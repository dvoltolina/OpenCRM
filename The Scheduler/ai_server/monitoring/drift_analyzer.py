"""
Drift Analyzer for Model Monitoring.

Detects data drift and concept drift by comparing recent predictions
with baseline distributions. Uses statistical tests to identify
significant changes.

Agent AI-17: Model Monitoring & Retraining Automation

HIPAA COMPLIANCE NOTES:
- Only aggregate statistics are analyzed, no PHI
- Feature values are not logged or stored
- All operations logged for audit trail
"""
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
import numpy as np
from scipy import stats

logger = logging.getLogger(__name__)


class DriftType(str, Enum):
    """Type of drift detected."""
    NONE = "none"
    DATA_DRIFT = "data_drift"
    CONCEPT_DRIFT = "concept_drift"
    BOTH = "both"


@dataclass
class DriftResult:
    """Result of drift detection analysis."""
    has_drift: bool
    drift_type: DriftType
    overall_score: float
    data_drift_score: float
    concept_drift_score: float
    data_drift_details: str
    concept_drift_details: str
    drifted_features: List[str]
    sample_size: int
    analysis_date: datetime
    has_baseline: bool = True
    has_sufficient_data: bool = True

    @property
    def summary(self) -> str:
        """Human-readable summary of drift analysis."""
        if not self.has_baseline:
            return "No baseline available for comparison"
        if not self.has_sufficient_data:
            return f"Insufficient data ({self.sample_size} samples)"
        if not self.has_drift:
            return "No significant drift detected"
        return f"{self.drift_type.value} detected (score: {self.overall_score:.2f})"


@dataclass
class BaselineStats:
    """Baseline statistics for drift comparison."""
    prediction_mean: float
    prediction_std: float
    feature_importances: Dict[str, float]
    calibration_error: float
    accuracy: float
    auc_roc: float
    created_at: datetime


class DriftAnalyzer:
    """
    Analyzes prediction distributions and model performance
    to detect data drift and concept drift.

    Data drift: Input feature distributions have shifted
    Concept drift: Relationship between features and outcome has changed
    """

    def __init__(
        self,
        firestore_client,
        drift_threshold: float = 2.0,
        calibration_threshold: float = 0.05,
        accuracy_threshold: float = 0.10,
        min_samples: int = 50,
    ):
        self.db = firestore_client
        self.drift_threshold = drift_threshold
        self.calibration_threshold = calibration_threshold
        self.accuracy_threshold = accuracy_threshold
        self.min_samples = min_samples

    async def detect_drift(
        self,
        business_id: str,
        model_version: str,
        recent_days: int = 7,
    ) -> DriftResult:
        """
        Detect drift by comparing recent predictions with baseline.

        Analyzes:
        1. Data drift: Prediction distribution shift (Z-score + variance ratio)
        2. Concept drift: Calibration and accuracy changes
        """
        # Get baseline statistics
        baseline = await self._get_baseline(business_id, model_version)
        if baseline is None:
            logger.warning(f"No baseline found for {business_id}/{model_version}")
            return DriftResult(
                has_drift=False,
                drift_type=DriftType.NONE,
                overall_score=0.0,
                data_drift_score=0.0,
                concept_drift_score=0.0,
                data_drift_details="No baseline available",
                concept_drift_details="No baseline available",
                drifted_features=[],
                sample_size=0,
                analysis_date=datetime.utcnow(),
                has_baseline=False,
                has_sufficient_data=False,
            )

        # Get recent outcomes
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=recent_days)

        outcomes = await self._get_outcomes(
            business_id=business_id,
            model_version=model_version,
            start_date=start_date,
            end_date=end_date,
        )

        if len(outcomes) < self.min_samples:
            logger.warning(
                f"Insufficient samples for drift detection: "
                f"{len(outcomes)} < {self.min_samples}"
            )
            return DriftResult(
                has_drift=False,
                drift_type=DriftType.NONE,
                overall_score=0.0,
                data_drift_score=0.0,
                concept_drift_score=0.0,
                data_drift_details=f"Insufficient data ({len(outcomes)} samples)",
                concept_drift_details=f"Insufficient data ({len(outcomes)} samples)",
                drifted_features=[],
                sample_size=len(outcomes),
                analysis_date=datetime.utcnow(),
                has_baseline=True,
                has_sufficient_data=False,
            )

        # Detect data drift
        data_drift_score, data_drift_details = self._detect_data_drift(
            outcomes, baseline
        )
        has_data_drift = data_drift_score > self.drift_threshold

        # Detect concept drift
        concept_drift_score, concept_drift_details = self._detect_concept_drift(
            outcomes, baseline
        )
        has_concept_drift = concept_drift_score > 0

        # Identify drifted features
        drifted_features = self._identify_drifted_features(outcomes, baseline)

        # Combine results
        drift_type = self._combine_drift_types(has_data_drift, has_concept_drift)
        overall_score = max(data_drift_score, concept_drift_score)

        result = DriftResult(
            has_drift=drift_type != DriftType.NONE,
            drift_type=drift_type,
            overall_score=overall_score,
            data_drift_score=data_drift_score,
            concept_drift_score=concept_drift_score,
            data_drift_details=data_drift_details,
            concept_drift_details=concept_drift_details,
            drifted_features=drifted_features,
            sample_size=len(outcomes),
            analysis_date=datetime.utcnow(),
        )

        logger.info(
            f"Drift analysis for {business_id}/{model_version}: "
            f"{result.summary}"
        )

        return result

    def _detect_data_drift(
        self,
        outcomes: List[Dict[str, Any]],
        baseline: BaselineStats,
    ) -> Tuple[float, str]:
        """
        Detect data drift by comparing prediction distributions.

        Uses Z-score of mean shift and variance ratio test.
        """
        if not outcomes:
            return 0.0, "No data"

        predictions = np.array([o["predicted_probability"] for o in outcomes])
        current_mean = predictions.mean()
        current_std = predictions.std() if len(predictions) > 1 else 0.0

        # Z-score of mean shift
        if baseline.prediction_std > 0:
            mean_shift = abs(current_mean - baseline.prediction_mean) / baseline.prediction_std
        else:
            mean_shift = 0.0

        # Variance ratio test
        if baseline.prediction_std > 0:
            variance_ratio = current_std / baseline.prediction_std
        else:
            variance_ratio = 1.0

        variance_shift = abs(variance_ratio - 1.0)

        # Combined drift score
        drift_score = mean_shift + variance_shift

        details = (
            f"Mean shift: {mean_shift:.2f} std, "
            f"Variance ratio: {variance_ratio:.2f}"
        )

        return drift_score, details

    def _detect_concept_drift(
        self,
        outcomes: List[Dict[str, Any]],
        baseline: BaselineStats,
    ) -> Tuple[float, str]:
        """
        Detect concept drift by analyzing calibration and accuracy changes.

        Concept drift indicates the relationship between features and
        outcomes has changed.
        """
        evaluable = [o for o in outcomes if o.get("actual_outcome") is not None]

        if len(evaluable) < 30:
            return 0.0, f"Insufficient evaluable outcomes ({len(evaluable)})"

        # Calculate current calibration error
        calibration_error = self._calculate_calibration_error(evaluable)
        calibration_increase = calibration_error - baseline.calibration_error

        # Calculate current accuracy
        current_accuracy = self._calculate_accuracy(evaluable)
        accuracy_drop = baseline.accuracy - current_accuracy

        # Concept drift score based on calibration and accuracy changes
        drift_score = (calibration_increase * 10) + (accuracy_drop * 5)
        drift_score = max(0, min(drift_score, 10))  # Clamp 0-10

        # Threshold checks
        has_concept_drift = (
            calibration_increase > self.calibration_threshold or
            accuracy_drop > self.accuracy_threshold
        )

        details = (
            f"Calibration change: {calibration_increase * 100:+.1f}%, "
            f"Accuracy change: {-accuracy_drop * 100:+.1f}%"
        )

        return drift_score if has_concept_drift else 0.0, details

    def _calculate_calibration_error(
        self,
        outcomes: List[Dict[str, Any]],
        num_bins: int = 10,
    ) -> float:
        """Calculate Expected Calibration Error (ECE)."""
        bin_counts = [0] * num_bins
        bin_sums = [0.0] * num_bins
        bin_positives = [0] * num_bins

        for outcome in outcomes:
            prob = outcome["predicted_probability"]
            actual = outcome["actual_outcome"]

            bin_idx = min(int(prob * num_bins), num_bins - 1)
            bin_counts[bin_idx] += 1
            bin_sums[bin_idx] += prob
            if actual:
                bin_positives[bin_idx] += 1

        ece = 0.0
        total = len(outcomes)

        for b in range(num_bins):
            if bin_counts[b] == 0:
                continue
            avg_prediction = bin_sums[b] / bin_counts[b]
            actual_rate = bin_positives[b] / bin_counts[b]
            ece += (bin_counts[b] / total) * abs(avg_prediction - actual_rate)

        return ece

    def _calculate_accuracy(self, outcomes: List[Dict[str, Any]]) -> float:
        """Calculate prediction accuracy at 0.5 threshold."""
        correct = 0
        total = 0

        for outcome in outcomes:
            if outcome.get("actual_outcome") is None:
                continue
            total += 1
            predicted = outcome["predicted_probability"] >= 0.5
            actual = outcome["actual_outcome"]
            if predicted == actual:
                correct += 1

        return correct / total if total > 0 else 0.0

    def _identify_drifted_features(
        self,
        outcomes: List[Dict[str, Any]],
        baseline: BaselineStats,
    ) -> List[str]:
        """
        Identify which features have drifted from baseline.

        Compares feature occurrence frequency with baseline importances.
        """
        feature_counts: Dict[str, int] = {}

        for outcome in outcomes:
            for feature in outcome.get("top_features", []):
                feature_counts[feature] = feature_counts.get(feature, 0) + 1

        drifted_features = []
        baseline_importances = baseline.feature_importances

        for feature, count in feature_counts.items():
            current_freq = count / len(outcomes) if outcomes else 0
            baseline_importance = baseline_importances.get(feature, 0.0)

            if abs(current_freq - baseline_importance) > 0.2:
                drifted_features.append(feature)

        return drifted_features[:5]  # Top 5 drifted features

    def _combine_drift_types(
        self,
        has_data_drift: bool,
        has_concept_drift: bool,
    ) -> DriftType:
        """Combine individual drift flags into overall drift type."""
        if has_data_drift and has_concept_drift:
            return DriftType.BOTH
        if has_data_drift:
            return DriftType.DATA_DRIFT
        if has_concept_drift:
            return DriftType.CONCEPT_DRIFT
        return DriftType.NONE

    async def _get_baseline(
        self,
        business_id: str,
        model_version: str,
    ) -> Optional[BaselineStats]:
        """Get baseline statistics from Firestore."""
        doc = await (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("model_baselines")
            .document(model_version)
            .get()
        )

        if not doc.exists:
            return None

        data = doc.to_dict()
        feature_stats = data.get("featureStats", {})
        pred_stats = feature_stats.get("predicted_probability", {})

        return BaselineStats(
            prediction_mean=pred_stats.get("mean", 0.3),
            prediction_std=pred_stats.get("stdDev", 0.2),
            feature_importances=data.get("featureImportances", {}),
            calibration_error=data.get("calibrationError", 0.05),
            accuracy=data.get("precision", 0.8),  # Using precision as proxy
            auc_roc=data.get("aucRoc", 0.8),
            created_at=data.get("createdAt", datetime.utcnow()),
        )

    async def _get_outcomes(
        self,
        business_id: str,
        model_version: str,
        start_date: datetime,
        end_date: datetime,
    ) -> List[Dict[str, Any]]:
        """Get prediction outcomes from Firestore."""
        docs = await (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("prediction_outcomes")
            .where("modelVersion", "==", model_version)
            .where("appointmentTime", ">=", start_date)
            .where("appointmentTime", "<", end_date)
            .get()
        )

        outcomes = []
        for doc in docs:
            data = doc.to_dict()
            outcome_str = data.get("outcome", "pending")

            # Map outcome to boolean
            actual_outcome = None
            if outcome_str == "noshow":
                actual_outcome = True
            elif outcome_str == "attended":
                actual_outcome = False

            outcomes.append({
                "predicted_probability": data.get("predictedProbability", 0.0),
                "actual_outcome": actual_outcome,
                "top_features": data.get("topFeatures", []),
            })

        return outcomes

    async def run_full_analysis(
        self,
        business_id: str,
        model_version: str,
    ) -> Dict[str, Any]:
        """
        Run full drift analysis and return comprehensive report.

        Includes drift detection, statistical tests, and recommendations.
        """
        drift_result = await self.detect_drift(
            business_id=business_id,
            model_version=model_version,
        )

        report = {
            "business_id": business_id,
            "model_version": model_version,
            "analysis_date": drift_result.analysis_date.isoformat(),
            "summary": drift_result.summary,
            "has_drift": drift_result.has_drift,
            "drift_type": drift_result.drift_type.value,
            "overall_score": drift_result.overall_score,
            "data_drift": {
                "score": drift_result.data_drift_score,
                "details": drift_result.data_drift_details,
            },
            "concept_drift": {
                "score": drift_result.concept_drift_score,
                "details": drift_result.concept_drift_details,
            },
            "drifted_features": drift_result.drifted_features,
            "sample_size": drift_result.sample_size,
            "recommendations": self._generate_recommendations(drift_result),
        }

        return report

    def _generate_recommendations(self, result: DriftResult) -> List[str]:
        """Generate actionable recommendations based on drift analysis."""
        recommendations = []

        if not result.has_baseline:
            recommendations.append(
                "Establish baseline metrics by training on historical data"
            )
            return recommendations

        if not result.has_sufficient_data:
            recommendations.append(
                f"Collect more prediction outcomes (minimum {self.min_samples} required)"
            )
            return recommendations

        if not result.has_drift:
            recommendations.append("Model performance is stable, no action needed")
            return recommendations

        if result.drift_type in (DriftType.DATA_DRIFT, DriftType.BOTH):
            recommendations.append(
                "Data distribution has shifted - consider retraining with recent data"
            )
            if result.drifted_features:
                recommendations.append(
                    f"Review changes in features: {', '.join(result.drifted_features)}"
                )

        if result.drift_type in (DriftType.CONCEPT_DRIFT, DriftType.BOTH):
            recommendations.append(
                "Model calibration has degraded - retraining recommended"
            )
            recommendations.append(
                "Review if business processes or client behavior has changed"
            )

        if result.overall_score > 5.0:
            recommendations.append(
                "URGENT: Significant drift detected, immediate retraining recommended"
            )

        return recommendations
