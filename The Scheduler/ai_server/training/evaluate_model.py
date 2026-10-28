"""
Evaluate trained no-show prediction model.

Agent AI-14: Model Training Pipeline

Usage:
    # Evaluate model on test data
    python evaluate_model.py --model models/noshow_model.lgb --test test_data.parquet

    # Generate full evaluation report
    python evaluate_model.py --model models/noshow_model.lgb --test test_data.parquet --report

    # Compare two models
    python evaluate_model.py --model models/v1.lgb --compare models/v2.lgb --test test_data.parquet

Features:
- Comprehensive metrics (AUC, precision, recall, F1, calibration)
- Confusion matrix and classification report
- ROC and Precision-Recall curves
- Calibration analysis
- Feature importance visualization
- Model comparison
- HTML/PDF report generation

HIPAA Note: Evaluation uses aggregate metrics only. No PHI in reports.
"""

import argparse
import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.calibration import calibration_curve
from sklearn.metrics import (
    accuracy_score,
    auc,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    recall_score,
    roc_auc_score,
    roc_curve,
)

try:
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt
    import seaborn as sns
    PLOTTING_AVAILABLE = True
except ImportError:
    PLOTTING_AVAILABLE = False
    plt = None
    sns = None


# Feature columns (must match training)
FEATURE_COLUMNS = [
    'clientHistoricalNoshowRate',
    'clientHistoricalCancelRate',
    'clientTotalAppointments',
    'clientDaysSinceLastVisit',
    'clientLifetimeValueCents',
    'clientLifecycleStage',
    'clientHasPaymentMethod',
    'bookingLeadDays',
    'dayOfWeek',
    'hourOfDay',
    'isRecurring',
    'isGroupSession',
    'serviceDurationMinutes',
    'servicePriceCents',
    'requiresPayment',
    'paymentCollected',
    'hasIntakeForm',
    'providerHistoricalNoshowRate',
    'providerTotalAppointments',
    'slotHistoricalNoshowRate',
    'isFirstAppointmentOfDay',
    'isLastAppointmentOfDay',
]

TARGET_COLUMN = 'noshow'

LIFECYCLE_ENCODING = {
    'newClient': 0,
    'active': 1,
    'inactive': 2,
    'churned': 3,
}


def load_model(model_path: str) -> Tuple[lgb.Booster, Optional[Dict]]:
    """Load model and metadata."""
    print(f"Loading model from: {model_path}")

    model = lgb.Booster(model_file=model_path)

    # Try to load metadata
    metadata_path = Path(model_path).with_suffix('.json')
    metadata = None
    if metadata_path.exists():
        with open(metadata_path) as f:
            metadata = json.load(f)
        print(f"Loaded metadata: version={metadata.get('version', 'unknown')}")

    return model, metadata


def load_test_data(data_path: str) -> Tuple[np.ndarray, np.ndarray]:
    """Load and preprocess test data."""
    print(f"Loading test data from: {data_path}")

    if data_path.endswith('.parquet'):
        df = pd.read_parquet(data_path)
    elif data_path.endswith('.csv'):
        df = pd.read_csv(data_path)
    else:
        raise ValueError(f"Unsupported file format: {data_path}")

    print(f"Loaded {len(df)} test samples")

    # Preprocess
    df = df.copy()
    df['clientLifecycleStage'] = df['clientLifecycleStage'].map(
        lambda x: LIFECYCLE_ENCODING.get(x, 0)
    )

    bool_cols = [
        'clientHasPaymentMethod', 'isRecurring', 'isGroupSession',
        'requiresPayment', 'paymentCollected', 'hasIntakeForm',
        'isFirstAppointmentOfDay', 'isLastAppointmentOfDay',
    ]
    for col in bool_cols:
        if col in df.columns:
            df[col] = df[col].astype(int)

    X = df[FEATURE_COLUMNS].values
    y = df[TARGET_COLUMN].values

    return X, y


def calculate_metrics(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
    threshold: float = 0.5,
) -> Dict[str, float]:
    """Calculate comprehensive evaluation metrics."""
    y_pred = (y_pred_proba >= threshold).astype(int)

    metrics = {
        'auc_roc': roc_auc_score(y_true, y_pred_proba),
        'accuracy': accuracy_score(y_true, y_pred),
        'precision': precision_score(y_true, y_pred, zero_division=0),
        'recall': recall_score(y_true, y_pred, zero_division=0),
        'f1': f1_score(y_true, y_pred, zero_division=0),
        'threshold': threshold,
        'n_samples': len(y_true),
        'n_positive': int(y_true.sum()),
        'n_negative': int(len(y_true) - y_true.sum()),
        'positive_rate': float(y_true.mean()),
    }

    # Precision-Recall AUC
    precision, recall, _ = precision_recall_curve(y_true, y_pred_proba)
    metrics['auc_pr'] = auc(recall, precision)

    # Confusion matrix values
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
    metrics['true_positives'] = int(tp)
    metrics['true_negatives'] = int(tn)
    metrics['false_positives'] = int(fp)
    metrics['false_negatives'] = int(fn)

    # Specificity
    metrics['specificity'] = tn / (tn + fp) if (tn + fp) > 0 else 0

    return metrics


def calculate_calibration(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
    n_bins: int = 10,
) -> Dict[str, Any]:
    """Calculate calibration metrics."""
    prob_true, prob_pred = calibration_curve(
        y_true, y_pred_proba, n_bins=n_bins, strategy='uniform'
    )

    # Expected Calibration Error (ECE)
    bin_counts = np.histogram(y_pred_proba, bins=n_bins, range=(0, 1))[0]
    ece = np.sum(
        bin_counts * np.abs(prob_true - prob_pred)
    ) / len(y_true) if len(y_true) > 0 else 0

    return {
        'expected_calibration_error': float(ece),
        'prob_true': prob_true.tolist(),
        'prob_pred': prob_pred.tolist(),
        'bin_counts': bin_counts.tolist(),
    }


def evaluate_at_thresholds(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
) -> List[Dict[str, float]]:
    """Evaluate metrics at different thresholds."""
    thresholds = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
    results = []

    for threshold in thresholds:
        metrics = calculate_metrics(y_true, y_pred_proba, threshold)
        results.append({
            'threshold': threshold,
            'precision': metrics['precision'],
            'recall': metrics['recall'],
            'f1': metrics['f1'],
            'specificity': metrics['specificity'],
        })

    return results


def get_feature_importance(model: lgb.Booster) -> Dict[str, float]:
    """Extract feature importance."""
    importance = model.feature_importance(importance_type='gain')
    feature_names = model.feature_name()

    total = importance.sum()
    if total > 0:
        importance = importance / total * 100

    return dict(sorted(
        zip(feature_names, importance),
        key=lambda x: x[1],
        reverse=True
    ))


def plot_roc_curve(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
    output_path: str,
) -> None:
    """Plot ROC curve."""
    if not PLOTTING_AVAILABLE:
        print("Matplotlib not available, skipping ROC plot")
        return

    fpr, tpr, _ = roc_curve(y_true, y_pred_proba)
    roc_auc = roc_auc_score(y_true, y_pred_proba)

    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {roc_auc:.3f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('Receiver Operating Characteristic (ROC) Curve')
    plt.legend(loc='lower right')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"ROC curve saved to: {output_path}")


def plot_precision_recall_curve(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
    output_path: str,
) -> None:
    """Plot Precision-Recall curve."""
    if not PLOTTING_AVAILABLE:
        print("Matplotlib not available, skipping PR plot")
        return

    precision, recall, thresholds = precision_recall_curve(y_true, y_pred_proba)
    pr_auc = auc(recall, precision)

    plt.figure(figsize=(8, 6))
    plt.plot(recall, precision, color='darkorange', lw=2, label=f'PR curve (AUC = {pr_auc:.3f})')
    plt.axhline(y=y_true.mean(), color='navy', lw=2, linestyle='--', label=f'Baseline ({y_true.mean():.3f})')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.title('Precision-Recall Curve')
    plt.legend(loc='upper right')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"PR curve saved to: {output_path}")


def plot_calibration_curve(
    y_true: np.ndarray,
    y_pred_proba: np.ndarray,
    output_path: str,
) -> None:
    """Plot calibration curve."""
    if not PLOTTING_AVAILABLE:
        print("Matplotlib not available, skipping calibration plot")
        return

    prob_true, prob_pred = calibration_curve(y_true, y_pred_proba, n_bins=10)

    plt.figure(figsize=(8, 6))
    plt.plot(prob_pred, prob_true, 's-', color='darkorange', lw=2, label='Model')
    plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Perfectly calibrated')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.0])
    plt.xlabel('Mean Predicted Probability')
    plt.ylabel('Fraction of Positives')
    plt.title('Calibration Curve')
    plt.legend(loc='upper left')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"Calibration curve saved to: {output_path}")


def plot_confusion_matrix(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    output_path: str,
) -> None:
    """Plot confusion matrix."""
    if not PLOTTING_AVAILABLE:
        print("Matplotlib not available, skipping confusion matrix plot")
        return

    cm = confusion_matrix(y_true, y_pred)

    plt.figure(figsize=(8, 6))
    sns.heatmap(
        cm, annot=True, fmt='d', cmap='Blues',
        xticklabels=['Show', 'No-Show'],
        yticklabels=['Show', 'No-Show'],
    )
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.title('Confusion Matrix')
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"Confusion matrix saved to: {output_path}")


def plot_feature_importance(
    importance: Dict[str, float],
    output_path: str,
    top_n: int = 15,
) -> None:
    """Plot feature importance."""
    if not PLOTTING_AVAILABLE:
        print("Matplotlib not available, skipping feature importance plot")
        return

    # Get top N features
    items = list(importance.items())[:top_n]
    features = [x[0] for x in items]
    values = [x[1] for x in items]

    plt.figure(figsize=(10, 8))
    plt.barh(range(len(features)), values, color='steelblue')
    plt.yticks(range(len(features)), features)
    plt.xlabel('Importance (%)')
    plt.title(f'Top {top_n} Feature Importance')
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    print(f"Feature importance plot saved to: {output_path}")


def generate_report(
    metrics: Dict[str, Any],
    calibration: Dict[str, Any],
    threshold_metrics: List[Dict],
    importance: Dict[str, float],
    output_dir: str,
    model_info: Optional[Dict] = None,
) -> str:
    """Generate evaluation report."""
    report_path = Path(output_dir) / "evaluation_report.json"

    report = {
        'generated_at': datetime.now().isoformat(),
        'model_info': model_info or {},
        'metrics': metrics,
        'calibration': calibration,
        'threshold_analysis': threshold_metrics,
        'feature_importance': importance,
    }

    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"Report saved to: {report_path}")
    return str(report_path)


def compare_models(
    model1_path: str,
    model2_path: str,
    X_test: np.ndarray,
    y_test: np.ndarray,
) -> Dict[str, Any]:
    """Compare two models."""
    print("\n" + "=" * 60)
    print("Model Comparison")
    print("=" * 60)

    model1, meta1 = load_model(model1_path)
    model2, meta2 = load_model(model2_path)

    # Get predictions
    y_pred1 = model1.predict(X_test)
    y_pred2 = model2.predict(X_test)

    # Calculate metrics
    metrics1 = calculate_metrics(y_test, y_pred1)
    metrics2 = calculate_metrics(y_test, y_pred2)

    comparison = {
        'model1': {
            'path': model1_path,
            'version': meta1.get('version', 'unknown') if meta1 else 'unknown',
            'metrics': metrics1,
        },
        'model2': {
            'path': model2_path,
            'version': meta2.get('version', 'unknown') if meta2 else 'unknown',
            'metrics': metrics2,
        },
        'differences': {},
    }

    # Calculate differences
    print("\nMetric Comparison:")
    print("-" * 50)
    for metric in ['auc_roc', 'precision', 'recall', 'f1']:
        diff = metrics2[metric] - metrics1[metric]
        comparison['differences'][metric] = diff
        direction = "+" if diff > 0 else ""
        print(f"  {metric:12s}: {metrics1[metric]:.4f} -> {metrics2[metric]:.4f} ({direction}{diff:.4f})")

    return comparison


def main():
    parser = argparse.ArgumentParser(
        description="Evaluate no-show prediction model"
    )
    parser.add_argument(
        "--model",
        required=True,
        help="Path to trained model (.lgb file)"
    )
    parser.add_argument(
        "--test",
        required=True,
        help="Path to test data (Parquet or CSV)"
    )
    parser.add_argument(
        "--output",
        default="evaluation",
        help="Output directory for reports and plots"
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Generate full evaluation report with plots"
    )
    parser.add_argument(
        "--compare",
        help="Path to second model for comparison"
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.5,
        help="Classification threshold"
    )

    args = parser.parse_args()

    print("=" * 60)
    print("The Scheduler - Model Evaluation")
    print("Agent AI-14: Model Training Pipeline")
    print("=" * 60)

    # Load model and data
    model, metadata = load_model(args.model)
    X_test, y_test = load_test_data(args.test)

    # Get predictions
    y_pred_proba = model.predict(X_test)

    # Calculate metrics
    metrics = calculate_metrics(y_test, y_pred_proba, args.threshold)

    print("\nEvaluation Metrics:")
    print("-" * 40)
    print(f"  AUC-ROC:     {metrics['auc_roc']:.4f}")
    print(f"  AUC-PR:      {metrics['auc_pr']:.4f}")
    print(f"  Accuracy:    {metrics['accuracy']:.4f}")
    print(f"  Precision:   {metrics['precision']:.4f}")
    print(f"  Recall:      {metrics['recall']:.4f}")
    print(f"  F1 Score:    {metrics['f1']:.4f}")
    print(f"  Specificity: {metrics['specificity']:.4f}")

    # Classification report
    y_pred = (y_pred_proba >= args.threshold).astype(int)
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=['Show', 'No-Show']))

    # Model comparison
    if args.compare:
        compare_models(args.model, args.compare, X_test, y_test)

    # Generate full report
    if args.report:
        output_dir = Path(args.output)
        output_dir.mkdir(parents=True, exist_ok=True)

        # Calibration
        calibration = calculate_calibration(y_test, y_pred_proba)
        print(f"\nExpected Calibration Error: {calibration['expected_calibration_error']:.4f}")

        # Threshold analysis
        threshold_metrics = evaluate_at_thresholds(y_test, y_pred_proba)

        # Feature importance
        importance = get_feature_importance(model)

        # Generate plots
        plot_roc_curve(y_test, y_pred_proba, str(output_dir / "roc_curve.png"))
        plot_precision_recall_curve(y_test, y_pred_proba, str(output_dir / "pr_curve.png"))
        plot_calibration_curve(y_test, y_pred_proba, str(output_dir / "calibration_curve.png"))
        plot_confusion_matrix(y_test, y_pred, str(output_dir / "confusion_matrix.png"))
        plot_feature_importance(importance, str(output_dir / "feature_importance.png"))

        # Generate report
        generate_report(
            metrics, calibration, threshold_metrics, importance,
            str(output_dir), metadata
        )

    print("\n" + "=" * 60)
    print("Evaluation complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
