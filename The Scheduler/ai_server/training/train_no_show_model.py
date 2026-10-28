"""
Train no-show prediction model using LightGBM.

Agent AI-14: Model Training Pipeline

Usage:
    # Train with default settings
    python train_no_show_model.py --data training_data.parquet

    # Train with hyperparameter tuning
    python train_no_show_model.py --data training_data.parquet --tune --trials 50

    # Train with specific output
    python train_no_show_model.py --data training_data.parquet --output models/noshow_v2.lgb

Features:
- LightGBM gradient boosting for binary classification
- Optuna hyperparameter tuning
- Class imbalance handling via SMOTE and class weights
- Cross-validation with stratified folds
- Model versioning with metadata
- Feature importance analysis

HIPAA Note: This script processes aggregate training data only.
No PHI is stored in the trained model or logs.
"""

import argparse
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import joblib
import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold, train_test_split
from sklearn.preprocessing import LabelEncoder

try:
    import optuna
    from optuna.samplers import TPESampler
    OPTUNA_AVAILABLE = True
except ImportError:
    OPTUNA_AVAILABLE = False
    optuna = None

try:
    from imblearn.over_sampling import SMOTE
    SMOTE_AVAILABLE = True
except ImportError:
    SMOTE_AVAILABLE = False
    SMOTE = None


# Feature columns (must match Flutter PredictionFeatures model)
FEATURE_COLUMNS = [
    'clientHistoricalNoshowRate',
    'clientHistoricalCancelRate',
    'clientTotalAppointments',
    'clientDaysSinceLastVisit',
    'clientLifetimeValueCents',
    'clientLifecycleStage',  # categorical
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

# Lifecycle stage encoding (matches Flutter model)
LIFECYCLE_ENCODING = {
    'newClient': 0,
    'active': 1,
    'inactive': 2,
    'churned': 3,
}


def load_data(data_path: str) -> pd.DataFrame:
    """Load and validate training data."""
    print(f"Loading data from: {data_path}")

    if data_path.endswith('.parquet'):
        df = pd.read_parquet(data_path)
    elif data_path.endswith('.csv'):
        df = pd.read_csv(data_path)
    else:
        raise ValueError(f"Unsupported file format: {data_path}")

    print(f"Loaded {len(df)} records")

    # Validate required columns
    missing = set(FEATURE_COLUMNS + [TARGET_COLUMN]) - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    return df


def preprocess_data(
    df: pd.DataFrame,
    use_smote: bool = False,
) -> Tuple[np.ndarray, np.ndarray, list]:
    """
    Preprocess data for training.

    Returns:
        X: Feature matrix
        y: Target vector
        feature_names: List of feature names
    """
    print("Preprocessing data...")

    # Copy to avoid modifying original
    df = df.copy()

    # Encode lifecycle stage
    df['clientLifecycleStage'] = df['clientLifecycleStage'].map(
        lambda x: LIFECYCLE_ENCODING.get(x, 0)
    )

    # Convert booleans to int
    bool_cols = [
        'clientHasPaymentMethod', 'isRecurring', 'isGroupSession',
        'requiresPayment', 'paymentCollected', 'hasIntakeForm',
        'isFirstAppointmentOfDay', 'isLastAppointmentOfDay',
    ]
    for col in bool_cols:
        if col in df.columns:
            df[col] = df[col].astype(int)

    # Extract features and target
    X = df[FEATURE_COLUMNS].values
    y = df[TARGET_COLUMN].values

    # Handle class imbalance with SMOTE
    if use_smote and SMOTE_AVAILABLE:
        print("Applying SMOTE for class balancing...")
        smote = SMOTE(random_state=42)
        X, y = smote.fit_resample(X, y)
        print(f"After SMOTE: {len(y)} samples")

    print(f"Features shape: {X.shape}")
    print(f"Positive class (no-show) rate: {y.mean():.2%}")

    return X, y, FEATURE_COLUMNS


def get_default_params() -> Dict[str, Any]:
    """Get default LightGBM parameters."""
    return {
        'objective': 'binary',
        'metric': 'auc',
        'boosting_type': 'gbdt',
        'num_leaves': 31,
        'learning_rate': 0.05,
        'feature_fraction': 0.9,
        'bagging_fraction': 0.8,
        'bagging_freq': 5,
        'min_child_samples': 20,
        'reg_alpha': 0.1,
        'reg_lambda': 0.1,
        'verbose': -1,
        'seed': 42,
    }


def tune_hyperparameters(
    X: np.ndarray,
    y: np.ndarray,
    n_trials: int = 50,
    cv_folds: int = 5,
) -> Dict[str, Any]:
    """
    Tune hyperparameters using Optuna.

    Returns:
        Best parameters dictionary
    """
    if not OPTUNA_AVAILABLE:
        raise ImportError("Optuna not installed. Run: pip install optuna")

    print(f"\nStarting hyperparameter tuning ({n_trials} trials)...")

    def objective(trial: optuna.Trial) -> float:
        params = {
            'objective': 'binary',
            'metric': 'auc',
            'boosting_type': 'gbdt',
            'verbose': -1,
            'seed': 42,
            'num_leaves': trial.suggest_int('num_leaves', 16, 128),
            'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'feature_fraction': trial.suggest_float('feature_fraction', 0.5, 1.0),
            'bagging_fraction': trial.suggest_float('bagging_fraction', 0.5, 1.0),
            'bagging_freq': trial.suggest_int('bagging_freq', 1, 10),
            'min_child_samples': trial.suggest_int('min_child_samples', 5, 100),
            'reg_alpha': trial.suggest_float('reg_alpha', 1e-8, 10.0, log=True),
            'reg_lambda': trial.suggest_float('reg_lambda', 1e-8, 10.0, log=True),
        }

        # Cross-validation
        cv = StratifiedKFold(n_splits=cv_folds, shuffle=True, random_state=42)
        scores = []

        for train_idx, val_idx in cv.split(X, y):
            X_train, X_val = X[train_idx], X[val_idx]
            y_train, y_val = y[train_idx], y[val_idx]

            train_data = lgb.Dataset(X_train, label=y_train)
            val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

            model = lgb.train(
                params,
                train_data,
                num_boost_round=1000,
                valid_sets=[val_data],
                callbacks=[
                    lgb.early_stopping(stopping_rounds=50),
                    lgb.log_evaluation(period=0),  # Suppress output
                ],
            )

            y_pred = model.predict(X_val)
            from sklearn.metrics import roc_auc_score
            scores.append(roc_auc_score(y_val, y_pred))

        return np.mean(scores)

    # Run optimization
    study = optuna.create_study(
        direction='maximize',
        sampler=TPESampler(seed=42),
    )
    study.optimize(objective, n_trials=n_trials, show_progress_bar=True)

    print(f"\nBest AUC: {study.best_value:.4f}")
    print(f"Best parameters: {study.best_params}")

    # Merge with defaults
    best_params = get_default_params()
    best_params.update(study.best_params)

    return best_params


def train_model(
    X: np.ndarray,
    y: np.ndarray,
    params: Dict[str, Any],
    test_size: float = 0.2,
    num_boost_round: int = 1000,
    early_stopping_rounds: int = 50,
) -> Tuple[lgb.Booster, Dict[str, float]]:
    """
    Train LightGBM model.

    Returns:
        Trained model and metrics dictionary
    """
    print("\nTraining model...")

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=42, stratify=y
    )

    # Calculate class weights
    n_pos = y_train.sum()
    n_neg = len(y_train) - n_pos
    scale_pos_weight = n_neg / n_pos if n_pos > 0 else 1.0
    params['scale_pos_weight'] = scale_pos_weight

    print(f"Training set: {len(y_train)} samples")
    print(f"Test set: {len(y_test)} samples")
    print(f"Scale pos weight: {scale_pos_weight:.2f}")

    # Create datasets
    train_data = lgb.Dataset(X_train, label=y_train, feature_name=FEATURE_COLUMNS)
    test_data = lgb.Dataset(X_test, label=y_test, reference=train_data)

    # Train
    model = lgb.train(
        params,
        train_data,
        num_boost_round=num_boost_round,
        valid_sets=[train_data, test_data],
        valid_names=['train', 'test'],
        callbacks=[
            lgb.early_stopping(stopping_rounds=early_stopping_rounds),
            lgb.log_evaluation(period=100),
        ],
    )

    # Evaluate on test set
    from sklearn.metrics import (
        accuracy_score,
        f1_score,
        precision_score,
        recall_score,
        roc_auc_score,
    )

    y_pred_proba = model.predict(X_test)
    y_pred = (y_pred_proba >= 0.5).astype(int)

    metrics = {
        'auc': roc_auc_score(y_test, y_pred_proba),
        'accuracy': accuracy_score(y_test, y_pred),
        'precision': precision_score(y_test, y_pred, zero_division=0),
        'recall': recall_score(y_test, y_pred, zero_division=0),
        'f1': f1_score(y_test, y_pred, zero_division=0),
        'test_samples': len(y_test),
        'train_samples': len(y_train),
        'noshow_rate': float(y.mean()),
        'best_iteration': model.best_iteration,
    }

    print("\nTest Set Metrics:")
    print(f"  AUC-ROC:   {metrics['auc']:.4f}")
    print(f"  Accuracy:  {metrics['accuracy']:.4f}")
    print(f"  Precision: {metrics['precision']:.4f}")
    print(f"  Recall:    {metrics['recall']:.4f}")
    print(f"  F1 Score:  {metrics['f1']:.4f}")

    return model, metrics


def get_feature_importance(model: lgb.Booster) -> Dict[str, float]:
    """Extract feature importance from trained model."""
    importance = model.feature_importance(importance_type='gain')
    feature_names = model.feature_name()

    # Normalize to percentages
    total = importance.sum()
    if total > 0:
        importance = importance / total * 100

    return dict(sorted(
        zip(feature_names, importance),
        key=lambda x: x[1],
        reverse=True
    ))


def save_model(
    model: lgb.Booster,
    output_path: str,
    metrics: Dict[str, float],
    params: Dict[str, Any],
    version: Optional[str] = None,
) -> str:
    """
    Save model with metadata.

    Returns:
        Path to saved model
    """
    output_dir = Path(output_path).parent
    if output_dir and not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)

    # Generate version if not provided
    if version is None:
        version = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Save model
    model_path = output_path
    model.save_model(model_path)
    print(f"\nModel saved to: {model_path}")

    # Save metadata
    metadata = {
        'version': version,
        'created_at': datetime.now().isoformat(),
        'model_type': 'lightgbm',
        'task': 'noshow_prediction',
        'features': FEATURE_COLUMNS,
        'num_features': len(FEATURE_COLUMNS),
        'params': {k: v for k, v in params.items() if not k.startswith('_')},
        'metrics': metrics,
        'feature_importance': get_feature_importance(model),
        'thresholds': {
            'high_risk': 0.7,
            'medium_risk': 0.4,
            'default': 0.5,
        },
    }

    metadata_path = str(Path(output_path).with_suffix('.json'))
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"Metadata saved to: {metadata_path}")

    return model_path


def main():
    parser = argparse.ArgumentParser(
        description="Train no-show prediction model using LightGBM"
    )
    parser.add_argument(
        "--data",
        required=True,
        help="Path to training data (Parquet or CSV)"
    )
    parser.add_argument(
        "--output",
        default="models/noshow_model.lgb",
        help="Output model path"
    )
    parser.add_argument(
        "--tune",
        action="store_true",
        help="Enable hyperparameter tuning with Optuna"
    )
    parser.add_argument(
        "--trials",
        type=int,
        default=50,
        help="Number of Optuna trials for hyperparameter tuning"
    )
    parser.add_argument(
        "--smote",
        action="store_true",
        help="Use SMOTE for class balancing"
    )
    parser.add_argument(
        "--test-size",
        type=float,
        default=0.2,
        help="Fraction of data for test set"
    )
    parser.add_argument(
        "--version",
        help="Model version string (default: timestamp)"
    )

    args = parser.parse_args()

    print("=" * 60)
    print("The Scheduler - No-Show Prediction Model Training")
    print("Agent AI-14: Model Training Pipeline")
    print("=" * 60)

    # Load data
    df = load_data(args.data)

    # Preprocess
    X, y, feature_names = preprocess_data(df, use_smote=args.smote)

    # Get parameters
    if args.tune:
        params = tune_hyperparameters(X, y, n_trials=args.trials)
    else:
        params = get_default_params()

    # Train model
    model, metrics = train_model(
        X, y, params,
        test_size=args.test_size,
    )

    # Print feature importance
    importance = get_feature_importance(model)
    print("\nTop 10 Feature Importance:")
    for i, (feat, imp) in enumerate(list(importance.items())[:10]):
        print(f"  {i+1}. {feat}: {imp:.1f}%")

    # Save model
    save_model(
        model,
        args.output,
        metrics,
        params,
        version=args.version,
    )

    print("\n" + "=" * 60)
    print("Training complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
