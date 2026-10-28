"""
Metrics Collector for Model Performance Monitoring.

Collects prediction outcomes and performance metrics from Firestore,
calculates rolling statistics, and stores snapshots for trend analysis.

Agent AI-17: Model Monitoring & Retraining Automation

HIPAA COMPLIANCE NOTES:
- Only aggregate metrics are collected, no PHI
- All operations are logged for audit trail
- Business ID isolation enforced
"""
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any
from dataclasses import dataclass, field
from enum import Enum
import numpy as np
from sklearn.metrics import roc_auc_score, precision_score, recall_score, f1_score, brier_score_loss

logger = logging.getLogger(__name__)


class PerformanceStatus(str, Enum):
    """Model performance status levels."""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    CRITICAL = "critical"
    INSUFFICIENT_DATA = "insufficient_data"


@dataclass
class PredictionOutcome:
    """A single prediction outcome for evaluation."""
    appointment_id: str
    business_id: str
    predicted_probability: float
    actual_outcome: bool  # True = no-show, False = attended
    model_version: str
    predicted_at: datetime
    appointment_time: datetime
    top_features: List[str] = field(default_factory=list)


@dataclass
class PerformanceSnapshot:
    """Performance metrics snapshot for a time period."""
    business_id: str
    model_version: str
    period_start: datetime
    period_end: datetime
    sample_size: int
    auc_roc: float
    precision_at_50: float
    recall_at_50: float
    f1_at_50: float
    brier_score: float
    calibration_error: float
    log_loss: float
    status: PerformanceStatus
    alerts: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class MonitoringThresholds:
    """Thresholds for monitoring alerts."""
    min_auc: float = 0.75
    max_calibration_error: float = 0.10
    auc_drop_threshold: float = 0.05
    min_sample_size: int = 50
    drift_threshold: float = 2.0
    min_outcomes_for_retraining: int = 1000


class MetricsCollector:
    """
    Collects and calculates model performance metrics.

    Fetches prediction outcomes from Firestore and computes:
    - AUC-ROC
    - Precision/Recall/F1 at 0.5 threshold
    - Brier score
    - Calibration error (ECE)
    - Log loss
    """

    def __init__(
        self,
        firestore_client,
        thresholds: Optional[MonitoringThresholds] = None,
    ):
        self.db = firestore_client
        self.thresholds = thresholds or MonitoringThresholds()

    async def collect_outcomes(
        self,
        business_id: str,
        start_date: datetime,
        end_date: datetime,
        model_version: Optional[str] = None,
    ) -> List[PredictionOutcome]:
        """
        Collect evaluable prediction outcomes from Firestore.

        Only outcomes where the appointment has concluded and
        outcome has been recorded are included.
        """
        outcomes_ref = (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("prediction_outcomes")
        )

        query = (
            outcomes_ref
            .where("appointmentTime", ">=", start_date)
            .where("appointmentTime", "<", end_date)
            .where("outcome", "in", ["attended", "noshow"])
        )

        if model_version:
            query = query.where("modelVersion", "==", model_version)

        docs = await query.get()

        outcomes = []
        for doc in docs:
            data = doc.to_dict()
            actual_noshow = data.get("outcome") == "noshow"

            outcomes.append(PredictionOutcome(
                appointment_id=data.get("appointmentId", ""),
                business_id=business_id,
                predicted_probability=data.get("predictedProbability", 0.0),
                actual_outcome=actual_noshow,
                model_version=data.get("modelVersion", "unknown"),
                predicted_at=data.get("predictedAt", datetime.utcnow()),
                appointment_time=data.get("appointmentTime", datetime.utcnow()),
                top_features=data.get("topFeatures", []),
            ))

        logger.info(
            f"Collected {len(outcomes)} outcomes for business {business_id} "
            f"from {start_date.date()} to {end_date.date()}"
        )

        return outcomes

    def calculate_metrics(
        self,
        outcomes: List[PredictionOutcome],
    ) -> Dict[str, float]:
        """
        Calculate performance metrics from outcomes.

        Returns dict with AUC, precision, recall, F1, Brier score,
        calibration error, and log loss.
        """
        if len(outcomes) < self.thresholds.min_sample_size:
            logger.warning(
                f"Insufficient samples for metrics: {len(outcomes)} < "
                f"{self.thresholds.min_sample_size}"
            )
            return {}

        predictions = np.array([o.predicted_probability for o in outcomes])
        actuals = np.array([1 if o.actual_outcome else 0 for o in outcomes])

        # Binary predictions at 0.5 threshold
        predicted_labels = (predictions >= 0.5).astype(int)

        # AUC-ROC
        try:
            auc = roc_auc_score(actuals, predictions)
        except ValueError:
            auc = 0.5  # Single class

        # Precision, Recall, F1
        precision = precision_score(actuals, predicted_labels, zero_division=0)
        recall = recall_score(actuals, predicted_labels, zero_division=0)
        f1 = f1_score(actuals, predicted_labels, zero_division=0)

        # Brier score
        brier = brier_score_loss(actuals, predictions)

        # Calibration error (Expected Calibration Error)
        calibration_error = self._calculate_ece(predictions, actuals)

        # Log loss
        log_loss_val = self._calculate_log_loss(predictions, actuals)

        return {
            "auc_roc": auc,
            "precision_at_50": precision,
            "recall_at_50": recall,
            "f1_at_50": f1,
            "brier_score": brier,
            "calibration_error": calibration_error,
            "log_loss": log_loss_val,
        }

    def _calculate_ece(
        self,
        predictions: np.ndarray,
        actuals: np.ndarray,
        num_bins: int = 10,
    ) -> float:
        """Calculate Expected Calibration Error."""
        bin_boundaries = np.linspace(0, 1, num_bins + 1)
        ece = 0.0

        for i in range(num_bins):
            in_bin = (predictions >= bin_boundaries[i]) & (predictions < bin_boundaries[i + 1])
            if i == num_bins - 1:  # Include 1.0 in last bin
                in_bin = (predictions >= bin_boundaries[i]) & (predictions <= bin_boundaries[i + 1])

            bin_size = in_bin.sum()
            if bin_size > 0:
                avg_prediction = predictions[in_bin].mean()
                actual_rate = actuals[in_bin].mean()
                ece += (bin_size / len(predictions)) * abs(avg_prediction - actual_rate)

        return ece

    def _calculate_log_loss(
        self,
        predictions: np.ndarray,
        actuals: np.ndarray,
        eps: float = 1e-15,
    ) -> float:
        """Calculate log loss (binary cross-entropy)."""
        predictions = np.clip(predictions, eps, 1 - eps)
        log_loss = -np.mean(
            actuals * np.log(predictions) + (1 - actuals) * np.log(1 - predictions)
        )
        return log_loss

    def determine_status(
        self,
        metrics: Dict[str, float],
        baseline: Optional[Dict[str, float]] = None,
    ) -> PerformanceStatus:
        """
        Determine performance status based on metrics and thresholds.
        """
        if not metrics:
            return PerformanceStatus.INSUFFICIENT_DATA

        # Critical if AUC below threshold
        if metrics.get("auc_roc", 1.0) < self.thresholds.min_auc:
            return PerformanceStatus.CRITICAL

        # Critical if calibration error too high
        if metrics.get("calibration_error", 0.0) > self.thresholds.max_calibration_error:
            return PerformanceStatus.CRITICAL

        # Degraded if significant drop from baseline
        if baseline:
            baseline_auc = baseline.get("auc_roc", metrics.get("auc_roc", 0.8))
            current_auc = metrics.get("auc_roc", 0.8)
            auc_drop = (baseline_auc - current_auc) / baseline_auc if baseline_auc > 0 else 0
            if auc_drop > self.thresholds.auc_drop_threshold:
                return PerformanceStatus.DEGRADED

        return PerformanceStatus.HEALTHY

    def generate_alerts(
        self,
        metrics: Dict[str, float],
        baseline: Optional[Dict[str, float]] = None,
    ) -> List[str]:
        """Generate alert messages based on metrics."""
        alerts = []

        if not metrics:
            return ["Insufficient data for metrics calculation"]

        auc = metrics.get("auc_roc", 1.0)
        if auc < self.thresholds.min_auc:
            alerts.append(
                f"AUC-ROC ({auc:.1%}) below threshold ({self.thresholds.min_auc:.0%})"
            )

        cal_error = metrics.get("calibration_error", 0.0)
        if cal_error > self.thresholds.max_calibration_error:
            alerts.append(
                f"Calibration error ({cal_error:.1%}) exceeds threshold "
                f"({self.thresholds.max_calibration_error:.0%})"
            )

        if baseline:
            baseline_auc = baseline.get("auc_roc", auc)
            if baseline_auc > 0:
                auc_drop = (baseline_auc - auc) / baseline_auc
                if auc_drop > self.thresholds.auc_drop_threshold:
                    alerts.append(
                        f"AUC dropped {auc_drop:.1%} from baseline"
                    )

        return alerts

    async def create_snapshot(
        self,
        business_id: str,
        model_version: str,
        start_date: datetime,
        end_date: datetime,
        baseline: Optional[Dict[str, float]] = None,
    ) -> Optional[PerformanceSnapshot]:
        """
        Create a performance snapshot for the given period.

        Collects outcomes, calculates metrics, and returns a snapshot.
        """
        outcomes = await self.collect_outcomes(
            business_id=business_id,
            start_date=start_date,
            end_date=end_date,
            model_version=model_version,
        )

        if len(outcomes) < self.thresholds.min_sample_size:
            logger.warning(
                f"Insufficient outcomes ({len(outcomes)}) for snapshot"
            )
            return None

        metrics = self.calculate_metrics(outcomes)

        if not metrics:
            return None

        status = self.determine_status(metrics, baseline)
        alerts = self.generate_alerts(metrics, baseline)

        snapshot = PerformanceSnapshot(
            business_id=business_id,
            model_version=model_version,
            period_start=start_date,
            period_end=end_date,
            sample_size=len(outcomes),
            auc_roc=metrics["auc_roc"],
            precision_at_50=metrics["precision_at_50"],
            recall_at_50=metrics["recall_at_50"],
            f1_at_50=metrics["f1_at_50"],
            brier_score=metrics["brier_score"],
            calibration_error=metrics["calibration_error"],
            log_loss=metrics["log_loss"],
            status=status,
            alerts=alerts,
        )

        logger.info(
            f"Created snapshot for {business_id}: AUC={metrics['auc_roc']:.3f}, "
            f"status={status.value}"
        )

        return snapshot

    async def save_snapshot(
        self,
        snapshot: PerformanceSnapshot,
    ) -> str:
        """Save a snapshot to Firestore. Returns document ID."""
        doc_ref = (
            self.db
            .collection("businesses")
            .document(snapshot.business_id)
            .collection("model_performance_snapshots")
            .document()
        )

        data = {
            "businessId": snapshot.business_id,
            "modelVersion": snapshot.model_version,
            "periodStart": snapshot.period_start,
            "periodEnd": snapshot.period_end,
            "sampleSize": snapshot.sample_size,
            "aucRoc": snapshot.auc_roc,
            "precisionAt50": snapshot.precision_at_50,
            "recallAt50": snapshot.recall_at_50,
            "f1At50": snapshot.f1_at_50,
            "brierScore": snapshot.brier_score,
            "calibrationError": snapshot.calibration_error,
            "logLoss": snapshot.log_loss,
            "status": snapshot.status.value,
            "alerts": snapshot.alerts,
            "createdAt": snapshot.created_at,
        }

        await doc_ref.set(data)

        logger.info(f"Saved snapshot {doc_ref.id} for {snapshot.business_id}")

        return doc_ref.id

    async def get_rolling_metrics(
        self,
        business_id: str,
        model_version: Optional[str] = None,
        days: int = 7,
    ) -> Optional[PerformanceSnapshot]:
        """
        Calculate rolling metrics for the past N days.
        """
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)

        # Get baseline for comparison
        baseline = await self._get_baseline(business_id, model_version)

        return await self.create_snapshot(
            business_id=business_id,
            model_version=model_version or "latest",
            start_date=start_date,
            end_date=end_date,
            baseline=baseline,
        )

    async def _get_baseline(
        self,
        business_id: str,
        model_version: Optional[str],
    ) -> Optional[Dict[str, float]]:
        """Get baseline metrics for a model version."""
        if not model_version:
            return None

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
        return {
            "auc_roc": data.get("aucRoc", 0.8),
            "precision": data.get("precision", 0.7),
            "recall": data.get("recall", 0.7),
            "calibration_error": data.get("calibrationError", 0.05),
        }
