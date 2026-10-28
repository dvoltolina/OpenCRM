"""
Retrain Scheduler for Automated Model Retraining.

Evaluates when retraining is needed and triggers retraining jobs
based on performance metrics, drift detection, and scheduling.

Agent AI-17: Model Monitoring & Retraining Automation

HIPAA COMPLIANCE NOTES:
- Only aggregate metrics are used for decisions
- All retraining triggers are logged for audit
- No PHI is included in retraining requests
"""
import logging
import asyncio
import aiohttp
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any
from dataclasses import dataclass, field
from enum import Enum

from .metrics_collector import MetricsCollector, PerformanceSnapshot, MonitoringThresholds
from .drift_analyzer import DriftAnalyzer, DriftResult, DriftType
from .alerting import AlertManager, AlertSeverity

logger = logging.getLogger(__name__)


class RetrainReason(str, Enum):
    """Reasons for triggering retraining."""
    LOW_AUC = "low_auc"
    HIGH_CALIBRATION_ERROR = "high_calibration_error"
    DRIFT_DETECTED = "drift_detected"
    NEW_DATA_ACCUMULATED = "new_data_accumulated"
    SCHEDULED_INTERVAL = "scheduled_interval"
    MANUAL_TRIGGER = "manual_trigger"


@dataclass
class RetrainEvaluation:
    """Result of retraining evaluation."""
    should_retrain: bool
    reasons: List[RetrainReason]
    snapshot: Optional[PerformanceSnapshot]
    drift_analysis: Optional[DriftResult]
    new_outcomes_count: int
    evaluated_at: datetime
    retrain_requested: bool = False
    retrain_job_id: Optional[str] = None
    error: Optional[str] = None

    @property
    def summary(self) -> str:
        """Human-readable summary of evaluation."""
        if not self.should_retrain:
            return "No retraining needed"
        if self.error:
            return f"Retraining evaluation failed: {self.error}"
        if self.retrain_requested:
            return f"Retraining triggered (job: {self.retrain_job_id or 'unknown'})"
        reason_names = [r.value for r in self.reasons]
        return f"Retraining recommended: {', '.join(reason_names)}"


@dataclass
class RetrainConfig:
    """Configuration for retraining scheduler."""
    # Thresholds
    min_auc: float = 0.75
    max_calibration_error: float = 0.10
    drift_threshold: float = 2.0
    min_outcomes_for_retraining: int = 1000

    # Scheduling
    scheduled_interval_days: int = 30
    evaluation_interval_hours: int = 6

    # Retraining endpoint
    retrain_endpoint: Optional[str] = None
    retrain_timeout_seconds: int = 300

    # Alerting
    alert_on_trigger: bool = True
    alert_on_failure: bool = True


class RetrainScheduler:
    """
    Scheduler for automated model retraining.

    Evaluates retraining conditions:
    1. AUC below threshold (e.g., 0.75)
    2. Calibration error above threshold
    3. Significant drift detected
    4. Sufficient new data accumulated
    5. Scheduled interval reached
    """

    def __init__(
        self,
        firestore_client,
        metrics_collector: MetricsCollector,
        drift_analyzer: DriftAnalyzer,
        alert_manager: Optional[AlertManager] = None,
        config: Optional[RetrainConfig] = None,
    ):
        self.db = firestore_client
        self.metrics_collector = metrics_collector
        self.drift_analyzer = drift_analyzer
        self.alert_manager = alert_manager
        self.config = config or RetrainConfig()

    async def evaluate_retraining(
        self,
        business_id: str,
        model_version: str,
        last_retrain_date: Optional[datetime] = None,
    ) -> RetrainEvaluation:
        """
        Evaluate whether retraining is needed.

        Checks all retraining conditions and returns evaluation result.
        """
        reasons: List[RetrainReason] = []
        snapshot: Optional[PerformanceSnapshot] = None
        drift_analysis: Optional[DriftResult] = None

        try:
            # 1. Check performance metrics
            snapshot = await self.metrics_collector.get_rolling_metrics(
                business_id=business_id,
                model_version=model_version,
                days=7,
            )

            if snapshot:
                if snapshot.auc_roc < self.config.min_auc:
                    reasons.append(RetrainReason.LOW_AUC)
                if snapshot.calibration_error > self.config.max_calibration_error:
                    reasons.append(RetrainReason.HIGH_CALIBRATION_ERROR)

            # 2. Check for drift
            drift_analysis = await self.drift_analyzer.detect_drift(
                business_id=business_id,
                model_version=model_version,
            )

            if drift_analysis.has_drift and drift_analysis.overall_score > self.config.drift_threshold:
                reasons.append(RetrainReason.DRIFT_DETECTED)

            # 3. Check for new data accumulation
            new_outcomes_count = await self._count_new_outcomes(
                business_id=business_id,
                since=last_retrain_date,
            )

            if new_outcomes_count >= self.config.min_outcomes_for_retraining:
                reasons.append(RetrainReason.NEW_DATA_ACCUMULATED)

            # 4. Check scheduled interval
            if last_retrain_date:
                days_since_retrain = (datetime.utcnow() - last_retrain_date).days
                if days_since_retrain >= self.config.scheduled_interval_days:
                    reasons.append(RetrainReason.SCHEDULED_INTERVAL)

            evaluation = RetrainEvaluation(
                should_retrain=len(reasons) > 0,
                reasons=reasons,
                snapshot=snapshot,
                drift_analysis=drift_analysis,
                new_outcomes_count=new_outcomes_count,
                evaluated_at=datetime.utcnow(),
            )

            logger.info(
                f"Retraining evaluation for {business_id}/{model_version}: "
                f"{evaluation.summary}"
            )

            return evaluation

        except Exception as e:
            logger.error(f"Error evaluating retraining: {e}")
            return RetrainEvaluation(
                should_retrain=False,
                reasons=[],
                snapshot=None,
                drift_analysis=None,
                new_outcomes_count=0,
                evaluated_at=datetime.utcnow(),
                error=str(e),
            )

    async def trigger_if_needed(
        self,
        business_id: str,
        model_version: str,
        last_retrain_date: Optional[datetime] = None,
        force_retrain: bool = False,
    ) -> RetrainEvaluation:
        """
        Evaluate and trigger retraining if conditions are met.

        Set force_retrain=True to bypass evaluation and trigger immediately.
        """
        evaluation = await self.evaluate_retraining(
            business_id=business_id,
            model_version=model_version,
            last_retrain_date=last_retrain_date,
        )

        if force_retrain:
            evaluation.reasons.append(RetrainReason.MANUAL_TRIGGER)
            evaluation.should_retrain = True

        if not evaluation.should_retrain:
            logger.info(f"Retraining not needed for {business_id}/{model_version}")
            return evaluation

        return await self._trigger_retraining(
            business_id=business_id,
            model_version=model_version,
            evaluation=evaluation,
        )

    async def manual_trigger(
        self,
        business_id: str,
        model_version: str,
        triggered_by: Optional[str] = None,
    ) -> RetrainEvaluation:
        """
        Manually trigger retraining.

        Used for admin-initiated retraining.
        """
        logger.info(
            f"Manual retraining triggered for {business_id}/{model_version} "
            f"by {triggered_by or 'unknown'}"
        )

        return await self.trigger_if_needed(
            business_id=business_id,
            model_version=model_version,
            force_retrain=True,
        )

    async def _trigger_retraining(
        self,
        business_id: str,
        model_version: str,
        evaluation: RetrainEvaluation,
    ) -> RetrainEvaluation:
        """
        Trigger the actual retraining job.
        """
        reason_names = [r.value for r in evaluation.reasons]
        logger.info(
            f"Triggering retraining for {business_id}/{model_version}. "
            f"Reasons: {', '.join(reason_names)}"
        )

        # Log retraining trigger in Firestore
        await self._log_retrain_trigger(
            business_id=business_id,
            model_version=model_version,
            reasons=evaluation.reasons,
            snapshot=evaluation.snapshot,
        )

        # Send alert if configured
        if self.alert_manager and self.config.alert_on_trigger:
            await self.alert_manager.send_alert(
                severity=AlertSeverity.WARNING,
                title=f"Model Retraining Triggered: {model_version}",
                message=(
                    f"Retraining triggered for {business_id}.\n"
                    f"Reasons: {', '.join(reason_names)}\n"
                    f"New outcomes: {evaluation.new_outcomes_count}"
                ),
                business_id=business_id,
                tags=["retraining", "model-monitoring"],
            )

        # Send retraining request if endpoint configured
        job_id: Optional[str] = None
        error: Optional[str] = None

        if self.config.retrain_endpoint:
            try:
                job_id = await self._send_retrain_request(
                    business_id=business_id,
                    model_version=model_version,
                    reasons=evaluation.reasons,
                )
            except Exception as e:
                error = str(e)
                logger.error(f"Failed to send retrain request: {e}")

                if self.alert_manager and self.config.alert_on_failure:
                    await self.alert_manager.send_alert(
                        severity=AlertSeverity.ERROR,
                        title=f"Retraining Request Failed: {model_version}",
                        message=f"Failed to trigger retraining: {error}",
                        business_id=business_id,
                        tags=["retraining", "error"],
                    )
        else:
            logger.info("No retrain endpoint configured, skipping HTTP request")

        # Update evaluation with results
        evaluation.retrain_requested = True
        evaluation.retrain_job_id = job_id
        evaluation.error = error

        return evaluation

    async def _send_retrain_request(
        self,
        business_id: str,
        model_version: str,
        reasons: List[RetrainReason],
    ) -> Optional[str]:
        """Send HTTP request to retraining endpoint."""
        if not self.config.retrain_endpoint:
            return None

        payload = {
            "business_id": business_id,
            "model_version": model_version,
            "reasons": [r.value for r in reasons],
            "timestamp": datetime.utcnow().isoformat(),
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(
                self.config.retrain_endpoint,
                json=payload,
                headers={
                    "Content-Type": "application/json",
                    "X-Business-ID": business_id,
                },
                timeout=aiohttp.ClientTimeout(total=self.config.retrain_timeout_seconds),
            ) as response:
                if response.status >= 200 and response.status < 300:
                    data = await response.json()
                    return data.get("job_id")
                else:
                    text = await response.text()
                    raise Exception(f"Retrain request failed: {response.status} - {text}")

    async def _count_new_outcomes(
        self,
        business_id: str,
        since: Optional[datetime] = None,
    ) -> int:
        """Count evaluable outcomes since the given date."""
        query = (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("prediction_outcomes")
            .where("outcome", "in", ["attended", "noshow"])
        )

        if since:
            query = query.where("outcomeRecordedAt", ">=", since)

        # Use count aggregation if available, otherwise get all docs
        try:
            count_result = await query.count().get()
            return count_result[0][0].value
        except Exception:
            # Fallback: fetch and count
            docs = await query.get()
            return len(docs)

    async def _log_retrain_trigger(
        self,
        business_id: str,
        model_version: str,
        reasons: List[RetrainReason],
        snapshot: Optional[PerformanceSnapshot],
    ):
        """Log retraining trigger to Firestore for audit."""
        doc_ref = (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("retrain_triggers")
            .document()
        )

        data = {
            "modelVersion": model_version,
            "reasons": [r.value for r in reasons],
            "triggeredAt": datetime.utcnow(),
            "snapshot": {
                "aucRoc": snapshot.auc_roc if snapshot else None,
                "calibrationError": snapshot.calibration_error if snapshot else None,
                "sampleSize": snapshot.sample_size if snapshot else None,
            } if snapshot else None,
        }

        await doc_ref.set(data)

    async def get_retrain_history(
        self,
        business_id: str,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """Get recent retraining trigger history."""
        docs = await (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("retrain_triggers")
            .order_by("triggeredAt", direction="DESCENDING")
            .limit(limit)
            .get()
        )

        return [doc.to_dict() for doc in docs]

    async def run_scheduled_evaluation(
        self,
        business_ids: List[str],
        model_version: str = "latest",
    ):
        """
        Run scheduled evaluation for multiple businesses.

        Designed to be called by a cron job or scheduler.
        """
        logger.info(
            f"Running scheduled retraining evaluation for "
            f"{len(business_ids)} businesses"
        )

        results = []

        for business_id in business_ids:
            try:
                # Get last retrain date
                last_retrain = await self._get_last_retrain_date(
                    business_id=business_id,
                    model_version=model_version,
                )

                evaluation = await self.trigger_if_needed(
                    business_id=business_id,
                    model_version=model_version,
                    last_retrain_date=last_retrain,
                )

                results.append({
                    "business_id": business_id,
                    "should_retrain": evaluation.should_retrain,
                    "reasons": [r.value for r in evaluation.reasons],
                    "triggered": evaluation.retrain_requested,
                    "error": evaluation.error,
                })

            except Exception as e:
                logger.error(f"Error evaluating {business_id}: {e}")
                results.append({
                    "business_id": business_id,
                    "error": str(e),
                })

        # Summary log
        triggered_count = sum(1 for r in results if r.get("triggered"))
        error_count = sum(1 for r in results if r.get("error"))

        logger.info(
            f"Scheduled evaluation complete: "
            f"{triggered_count} retraining triggered, "
            f"{error_count} errors"
        )

        return results

    async def _get_last_retrain_date(
        self,
        business_id: str,
        model_version: str,
    ) -> Optional[datetime]:
        """Get the date of the last retraining."""
        docs = await (
            self.db
            .collection("businesses")
            .document(business_id)
            .collection("retrain_triggers")
            .where("modelVersion", "==", model_version)
            .order_by("triggeredAt", direction="DESCENDING")
            .limit(1)
            .get()
        )

        if docs:
            data = docs[0].to_dict()
            return data.get("triggeredAt")

        return None
