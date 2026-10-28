"""
Unit tests for Model Monitoring components.

Agent AI-17: Model Monitoring & Retraining Automation

Tests cover:
- MetricsCollector calculations
- DriftAnalyzer detection
- RetrainScheduler evaluation
- AlertManager sending
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
import numpy as np

# Import monitoring components
import sys
sys.path.insert(0, "..")
from monitoring.metrics_collector import (
    MetricsCollector,
    PredictionOutcome,
    PerformanceSnapshot,
    PerformanceStatus,
    MonitoringThresholds,
)
from monitoring.drift_analyzer import (
    DriftAnalyzer,
    DriftType,
    DriftResult,
    BaselineStats,
)
from monitoring.retrain_scheduler import (
    RetrainScheduler,
    RetrainReason,
    RetrainEvaluation,
    RetrainConfig,
)
from monitoring.alerting import (
    AlertManager,
    AlertSeverity,
    AlertChannel,
    AlertConfig,
    Alert,
)


class TestMetricsCollector:
    """Tests for MetricsCollector."""

    @pytest.fixture
    def mock_firestore(self):
        """Create mock Firestore client."""
        return MagicMock()

    @pytest.fixture
    def collector(self, mock_firestore):
        """Create MetricsCollector instance."""
        return MetricsCollector(
            firestore_client=mock_firestore,
            thresholds=MonitoringThresholds(min_sample_size=10),
        )

    def test_calculate_metrics_perfect_predictions(self, collector):
        """Test metrics with perfect predictions."""
        # Create outcomes where predictions perfectly match actuals
        outcomes = []
        for i in range(100):
            is_noshow = i < 20  # 20% no-show rate
            prob = 0.9 if is_noshow else 0.1

            outcomes.append(PredictionOutcome(
                appointment_id=f"apt_{i}",
                business_id="test_business",
                predicted_probability=prob,
                actual_outcome=is_noshow,
                model_version="v1.0",
                predicted_at=datetime.utcnow(),
                appointment_time=datetime.utcnow(),
            ))

        metrics = collector.calculate_metrics(outcomes)

        assert metrics["auc_roc"] > 0.95  # Near perfect AUC
        assert metrics["precision_at_50"] > 0.9
        assert metrics["recall_at_50"] > 0.9
        assert metrics["calibration_error"] < 0.1

    def test_calculate_metrics_random_predictions(self, collector):
        """Test metrics with random predictions."""
        np.random.seed(42)
        outcomes = []

        for i in range(100):
            is_noshow = np.random.random() < 0.3
            prob = np.random.random()  # Random prediction

            outcomes.append(PredictionOutcome(
                appointment_id=f"apt_{i}",
                business_id="test_business",
                predicted_probability=prob,
                actual_outcome=is_noshow,
                model_version="v1.0",
                predicted_at=datetime.utcnow(),
                appointment_time=datetime.utcnow(),
            ))

        metrics = collector.calculate_metrics(outcomes)

        # Random predictions should have AUC around 0.5
        assert 0.3 < metrics["auc_roc"] < 0.7

    def test_calculate_metrics_insufficient_data(self, collector):
        """Test metrics with insufficient samples."""
        outcomes = [
            PredictionOutcome(
                appointment_id="apt_1",
                business_id="test_business",
                predicted_probability=0.5,
                actual_outcome=True,
                model_version="v1.0",
                predicted_at=datetime.utcnow(),
                appointment_time=datetime.utcnow(),
            )
        ]

        metrics = collector.calculate_metrics(outcomes)
        assert metrics == {}  # Empty when insufficient data

    def test_determine_status_healthy(self, collector):
        """Test healthy status determination."""
        metrics = {
            "auc_roc": 0.85,
            "calibration_error": 0.05,
        }

        status = collector.determine_status(metrics, baseline=None)
        assert status == PerformanceStatus.HEALTHY

    def test_determine_status_critical_low_auc(self, collector):
        """Test critical status when AUC is too low."""
        metrics = {
            "auc_roc": 0.65,  # Below 0.75 threshold
            "calibration_error": 0.05,
        }

        status = collector.determine_status(metrics, baseline=None)
        assert status == PerformanceStatus.CRITICAL

    def test_determine_status_critical_high_calibration(self, collector):
        """Test critical status when calibration error is too high."""
        metrics = {
            "auc_roc": 0.85,
            "calibration_error": 0.15,  # Above 0.10 threshold
        }

        status = collector.determine_status(metrics, baseline=None)
        assert status == PerformanceStatus.CRITICAL

    def test_determine_status_degraded_from_baseline(self, collector):
        """Test degraded status when AUC drops significantly from baseline."""
        metrics = {
            "auc_roc": 0.77,
            "calibration_error": 0.05,
        }
        baseline = {
            "auc_roc": 0.85,  # 9.4% drop
        }

        status = collector.determine_status(metrics, baseline)
        assert status == PerformanceStatus.DEGRADED

    def test_generate_alerts(self, collector):
        """Test alert generation."""
        metrics = {
            "auc_roc": 0.70,
            "calibration_error": 0.12,
        }
        baseline = {"auc_roc": 0.85}

        alerts = collector.generate_alerts(metrics, baseline)

        assert len(alerts) == 3  # Low AUC, high calibration, AUC drop
        assert any("AUC-ROC" in a for a in alerts)
        assert any("Calibration" in a for a in alerts)
        assert any("dropped" in a for a in alerts)


class TestDriftAnalyzer:
    """Tests for DriftAnalyzer."""

    @pytest.fixture
    def mock_firestore(self):
        """Create mock Firestore client."""
        return MagicMock()

    @pytest.fixture
    def analyzer(self, mock_firestore):
        """Create DriftAnalyzer instance."""
        return DriftAnalyzer(
            firestore_client=mock_firestore,
            drift_threshold=2.0,
            min_samples=10,
        )

    def test_detect_data_drift_no_drift(self, analyzer):
        """Test data drift detection with no drift."""
        outcomes = [
            {"predicted_probability": 0.3 + np.random.normal(0, 0.1)}
            for _ in range(50)
        ]

        baseline = BaselineStats(
            prediction_mean=0.3,
            prediction_std=0.2,
            feature_importances={},
            calibration_error=0.05,
            accuracy=0.8,
            auc_roc=0.8,
            created_at=datetime.utcnow(),
        )

        score, details = analyzer._detect_data_drift(outcomes, baseline)

        assert score < 2.0  # Below threshold
        assert "Mean shift" in details

    def test_detect_data_drift_with_drift(self, analyzer):
        """Test data drift detection with significant drift."""
        # Outcomes with much higher mean than baseline
        outcomes = [
            {"predicted_probability": 0.8 + np.random.normal(0, 0.05)}
            for _ in range(50)
        ]

        baseline = BaselineStats(
            prediction_mean=0.3,
            prediction_std=0.1,
            feature_importances={},
            calibration_error=0.05,
            accuracy=0.8,
            auc_roc=0.8,
            created_at=datetime.utcnow(),
        )

        score, details = analyzer._detect_data_drift(outcomes, baseline)

        assert score > 2.0  # Above threshold (5 std shift)

    def test_detect_concept_drift_no_drift(self, analyzer):
        """Test concept drift detection with no drift."""
        outcomes = [
            {
                "predicted_probability": 0.7 if i < 20 else 0.3,
                "actual_outcome": i < 20,  # Matches predictions
            }
            for i in range(100)
        ]

        baseline = BaselineStats(
            prediction_mean=0.3,
            prediction_std=0.2,
            feature_importances={},
            calibration_error=0.05,
            accuracy=0.8,
            auc_roc=0.8,
            created_at=datetime.utcnow(),
        )

        score, details = analyzer._detect_concept_drift(outcomes, baseline)

        assert score == 0  # No concept drift

    def test_calculate_calibration_error(self, analyzer):
        """Test ECE calculation."""
        # Well-calibrated predictions
        outcomes = []
        for prob in [0.1, 0.3, 0.5, 0.7, 0.9]:
            for _ in range(20):
                actual = np.random.random() < prob
                outcomes.append({
                    "predicted_probability": prob,
                    "actual_outcome": actual,
                })

        ece = analyzer._calculate_calibration_error(outcomes)

        # Well-calibrated model should have low ECE
        assert ece < 0.2

    def test_calculate_accuracy(self, analyzer):
        """Test accuracy calculation."""
        outcomes = [
            {"predicted_probability": 0.8, "actual_outcome": True},
            {"predicted_probability": 0.7, "actual_outcome": True},
            {"predicted_probability": 0.2, "actual_outcome": False},
            {"predicted_probability": 0.3, "actual_outcome": False},
            {"predicted_probability": 0.6, "actual_outcome": False},  # Wrong
        ]

        accuracy = analyzer._calculate_accuracy(outcomes)

        assert accuracy == 0.8  # 4/5 correct

    def test_combine_drift_types(self, analyzer):
        """Test drift type combination."""
        assert analyzer._combine_drift_types(False, False) == DriftType.NONE
        assert analyzer._combine_drift_types(True, False) == DriftType.DATA_DRIFT
        assert analyzer._combine_drift_types(False, True) == DriftType.CONCEPT_DRIFT
        assert analyzer._combine_drift_types(True, True) == DriftType.BOTH


class TestRetrainScheduler:
    """Tests for RetrainScheduler."""

    @pytest.fixture
    def mock_firestore(self):
        """Create mock Firestore client."""
        return MagicMock()

    @pytest.fixture
    def mock_metrics_collector(self):
        """Create mock MetricsCollector."""
        collector = MagicMock(spec=MetricsCollector)
        collector.get_rolling_metrics = AsyncMock()
        return collector

    @pytest.fixture
    def mock_drift_analyzer(self):
        """Create mock DriftAnalyzer."""
        analyzer = MagicMock(spec=DriftAnalyzer)
        analyzer.detect_drift = AsyncMock()
        return analyzer

    @pytest.fixture
    def scheduler(self, mock_firestore, mock_metrics_collector, mock_drift_analyzer):
        """Create RetrainScheduler instance."""
        return RetrainScheduler(
            firestore_client=mock_firestore,
            metrics_collector=mock_metrics_collector,
            drift_analyzer=mock_drift_analyzer,
            config=RetrainConfig(
                min_auc=0.75,
                min_outcomes_for_retraining=100,
            ),
        )

    @pytest.mark.asyncio
    async def test_evaluate_no_retrain_needed(
        self,
        scheduler,
        mock_metrics_collector,
        mock_drift_analyzer,
    ):
        """Test evaluation when no retraining is needed."""
        # Mock healthy metrics
        mock_metrics_collector.get_rolling_metrics.return_value = PerformanceSnapshot(
            business_id="test",
            model_version="v1.0",
            period_start=datetime.utcnow() - timedelta(days=7),
            period_end=datetime.utcnow(),
            sample_size=100,
            auc_roc=0.85,
            precision_at_50=0.8,
            recall_at_50=0.7,
            f1_at_50=0.75,
            brier_score=0.15,
            calibration_error=0.05,
            log_loss=0.4,
            status=PerformanceStatus.HEALTHY,
        )

        # Mock no drift
        mock_drift_analyzer.detect_drift.return_value = DriftResult(
            has_drift=False,
            drift_type=DriftType.NONE,
            overall_score=0.5,
            data_drift_score=0.3,
            concept_drift_score=0.2,
            data_drift_details="",
            concept_drift_details="",
            drifted_features=[],
            sample_size=100,
            analysis_date=datetime.utcnow(),
        )

        # Mock low outcome count
        scheduler._count_new_outcomes = AsyncMock(return_value=50)

        evaluation = await scheduler.evaluate_retraining(
            business_id="test",
            model_version="v1.0",
            last_retrain_date=datetime.utcnow() - timedelta(days=10),
        )

        assert not evaluation.should_retrain
        assert len(evaluation.reasons) == 0

    @pytest.mark.asyncio
    async def test_evaluate_low_auc_triggers_retrain(
        self,
        scheduler,
        mock_metrics_collector,
        mock_drift_analyzer,
    ):
        """Test evaluation triggers retrain when AUC is low."""
        # Mock low AUC metrics
        mock_metrics_collector.get_rolling_metrics.return_value = PerformanceSnapshot(
            business_id="test",
            model_version="v1.0",
            period_start=datetime.utcnow() - timedelta(days=7),
            period_end=datetime.utcnow(),
            sample_size=100,
            auc_roc=0.70,  # Below threshold
            precision_at_50=0.6,
            recall_at_50=0.5,
            f1_at_50=0.55,
            brier_score=0.25,
            calibration_error=0.08,
            log_loss=0.5,
            status=PerformanceStatus.CRITICAL,
        )

        mock_drift_analyzer.detect_drift.return_value = DriftResult(
            has_drift=False,
            drift_type=DriftType.NONE,
            overall_score=0.5,
            data_drift_score=0.3,
            concept_drift_score=0.2,
            data_drift_details="",
            concept_drift_details="",
            drifted_features=[],
            sample_size=100,
            analysis_date=datetime.utcnow(),
        )

        scheduler._count_new_outcomes = AsyncMock(return_value=50)

        evaluation = await scheduler.evaluate_retraining(
            business_id="test",
            model_version="v1.0",
        )

        assert evaluation.should_retrain
        assert RetrainReason.LOW_AUC in evaluation.reasons

    @pytest.mark.asyncio
    async def test_evaluate_drift_triggers_retrain(
        self,
        scheduler,
        mock_metrics_collector,
        mock_drift_analyzer,
    ):
        """Test evaluation triggers retrain when drift is detected."""
        mock_metrics_collector.get_rolling_metrics.return_value = PerformanceSnapshot(
            business_id="test",
            model_version="v1.0",
            period_start=datetime.utcnow() - timedelta(days=7),
            period_end=datetime.utcnow(),
            sample_size=100,
            auc_roc=0.80,
            precision_at_50=0.75,
            recall_at_50=0.7,
            f1_at_50=0.72,
            brier_score=0.18,
            calibration_error=0.06,
            log_loss=0.45,
            status=PerformanceStatus.HEALTHY,
        )

        # Mock significant drift
        mock_drift_analyzer.detect_drift.return_value = DriftResult(
            has_drift=True,
            drift_type=DriftType.DATA_DRIFT,
            overall_score=3.5,  # Above threshold
            data_drift_score=3.5,
            concept_drift_score=0.5,
            data_drift_details="Significant mean shift",
            concept_drift_details="",
            drifted_features=["feature_a", "feature_b"],
            sample_size=100,
            analysis_date=datetime.utcnow(),
        )

        scheduler._count_new_outcomes = AsyncMock(return_value=50)

        evaluation = await scheduler.evaluate_retraining(
            business_id="test",
            model_version="v1.0",
        )

        assert evaluation.should_retrain
        assert RetrainReason.DRIFT_DETECTED in evaluation.reasons


class TestAlertManager:
    """Tests for AlertManager."""

    @pytest.fixture
    def alert_manager(self):
        """Create AlertManager instance."""
        return AlertManager(
            config=AlertConfig(
                enabled_channels=[AlertChannel.LOG],
                max_alerts_per_hour=10,
                dedupe_window_minutes=5,
            )
        )

    @pytest.mark.asyncio
    async def test_send_alert_logs(self, alert_manager, caplog):
        """Test that alerts are logged."""
        import logging
        caplog.set_level(logging.WARNING)

        result = await alert_manager.send_alert(
            severity=AlertSeverity.WARNING,
            title="Test Alert",
            message="This is a test alert",
            business_id="test_business",
        )

        assert result is True
        assert "Test Alert" in caplog.text

    @pytest.mark.asyncio
    async def test_rate_limiting(self, alert_manager):
        """Test alert rate limiting."""
        alert_manager.config.max_alerts_per_hour = 3

        # Send 3 alerts (should succeed)
        for i in range(3):
            result = await alert_manager.send_alert(
                severity=AlertSeverity.INFO,
                title=f"Alert {i}",
                message="Test",
            )
            assert result is True

        # 4th alert should be rate limited
        result = await alert_manager.send_alert(
            severity=AlertSeverity.INFO,
            title="Alert 4",
            message="Test",
        )
        assert result is False

    @pytest.mark.asyncio
    async def test_deduplication(self, alert_manager):
        """Test alert deduplication."""
        # First alert should succeed
        result1 = await alert_manager.send_alert(
            severity=AlertSeverity.WARNING,
            title="Duplicate Alert",
            message="Test",
            business_id="test",
        )
        assert result1 is True

        # Same alert within dedupe window should be skipped
        result2 = await alert_manager.send_alert(
            severity=AlertSeverity.WARNING,
            title="Duplicate Alert",
            message="Test",
            business_id="test",
        )
        assert result2 is False

        # Different alert should succeed
        result3 = await alert_manager.send_alert(
            severity=AlertSeverity.WARNING,
            title="Different Alert",
            message="Test",
            business_id="test",
        )
        assert result3 is True

    def test_get_emoji(self, alert_manager):
        """Test emoji selection."""
        assert alert_manager._get_emoji(AlertSeverity.INFO) == "ℹ️"
        assert alert_manager._get_emoji(AlertSeverity.WARNING) == "⚠️"
        assert alert_manager._get_emoji(AlertSeverity.ERROR) == "🚨"
        assert alert_manager._get_emoji(AlertSeverity.CRITICAL) == "🔥"

    def test_get_severity_color(self, alert_manager):
        """Test color selection."""
        assert alert_manager._get_severity_color(AlertSeverity.INFO) == "#36a64f"
        assert alert_manager._get_severity_color(AlertSeverity.ERROR) == "#dc3545"


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
