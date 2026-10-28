"""
Tests for model loading and inference.
Run with: pytest tests/test_model.py -v

Agent AI-3: Python Prediction Server
"""
import pytest
from datetime import datetime

from ..model import ModelManager
from ..schemas import PredictionFeaturesRequest, RiskLevel


@pytest.fixture
def model_manager():
    """Create model manager in mock mode."""
    manager = ModelManager(models_dir="nonexistent_dir")
    manager.load_model("noshow_model")
    return manager


@pytest.fixture
def sample_features():
    """Create sample prediction features."""
    return PredictionFeaturesRequest(
        appointment_id="test_appt_123",
        business_id="test_business_456",
        feature_schema_version=1,
        client_historical_noshow_rate=0.15,
        client_historical_cancel_rate=0.10,
        client_total_appointments=8,
        client_days_since_last_visit=30,
        client_lifetime_value_cents=50000,
        client_lifecycle_stage="active",
        client_has_payment_method=True,
        booking_lead_days=7,
        day_of_week=2,
        hour_of_day=14,
        is_recurring=False,
        is_group_session=False,
        service_duration_minutes=60,
        service_price_cents=10000,
        requires_payment=True,
        payment_collected=True,
        has_intake_form=True,
        provider_historical_noshow_rate=0.08,
        provider_total_appointments=500,
        slot_historical_noshow_rate=0.12,
        is_first_appointment_of_day=False,
        is_last_appointment_of_day=False,
    )


class TestModelManager:
    """Tests for ModelManager class."""

    def test_load_model_mock_mode(self, model_manager):
        """Test model loads in mock mode when no model file exists."""
        assert model_manager.is_loaded
        assert model_manager.is_mock
        assert model_manager.metadata is not None
        assert "mock" in model_manager.metadata.version.lower()

    def test_predict_returns_valid_response(self, model_manager, sample_features):
        """Test prediction returns valid response structure."""
        prediction = model_manager.predict(sample_features)

        assert prediction.appointment_id == "test_appt_123"
        assert 0.0 <= prediction.probability <= 1.0
        assert prediction.risk_level in RiskLevel
        assert 0.0 <= prediction.confidence <= 1.0
        assert isinstance(prediction.recommended_actions, list)
        assert isinstance(prediction.top_features, list)
        assert len(prediction.top_features) <= 5
        assert prediction.predicted_at is not None
        assert prediction.expires_at is not None
        assert prediction.expires_at > prediction.predicted_at

    def test_predict_batch(self, model_manager, sample_features):
        """Test batch prediction."""
        features_list = [sample_features, sample_features, sample_features]
        predictions = model_manager.predict_batch(features_list)

        assert len(predictions) == 3
        for pred in predictions:
            assert 0.0 <= pred.probability <= 1.0

    def test_risk_level_thresholds(self, model_manager, sample_features):
        """Test that risk level is correctly calculated based on thresholds."""
        # Test with different threshold configurations
        prediction_high = model_manager.predict(
            sample_features,
            high_risk_threshold=0.1,  # Very low threshold
            medium_risk_threshold=0.05,
        )
        # With low thresholds and typical prediction, should be high risk

        prediction_low = model_manager.predict(
            sample_features,
            high_risk_threshold=0.99,
            medium_risk_threshold=0.98,
        )
        # With very high thresholds, should be low risk
        assert prediction_low.risk_level == RiskLevel.LOW

    def test_feature_importances(self, model_manager, sample_features):
        """Test that feature importances are calculated."""
        prediction = model_manager.predict(sample_features)

        assert len(prediction.top_features) > 0
        for feature in prediction.top_features:
            assert 0.0 <= feature.importance <= 1.0
            assert feature.feature_name != ""
            assert feature.feature_display_name != ""
            assert feature.impact in ["increases_risk", "decreases_risk"]

    def test_recommendations_for_high_risk(self, model_manager):
        """Test that high risk predictions have appropriate recommendations."""
        high_risk_features = PredictionFeaturesRequest(
            appointment_id="high_risk",
            business_id="test",
            feature_schema_version=1,
            client_historical_noshow_rate=0.8,  # Very high
            client_historical_cancel_rate=0.5,
            client_total_appointments=2,
            client_days_since_last_visit=120,
            client_lifetime_value_cents=1000,
            client_lifecycle_stage="churned",
            client_has_payment_method=False,
            booking_lead_days=30,
            day_of_week=1,
            hour_of_day=8,
            is_recurring=False,
            is_group_session=False,
            service_duration_minutes=30,
            service_price_cents=5000,
            requires_payment=True,
            payment_collected=False,
            has_intake_form=False,
            provider_historical_noshow_rate=0.2,
            provider_total_appointments=50,
            slot_historical_noshow_rate=0.3,
            is_first_appointment_of_day=True,
            is_last_appointment_of_day=False,
        )

        prediction = model_manager.predict(
            high_risk_features,
            high_risk_threshold=0.4,  # Lower threshold to ensure high risk
        )

        # Should have recommendations
        assert len(prediction.recommended_actions) > 0

        # High risk should have critical/high priority actions
        priorities = [a.priority.value for a in prediction.recommended_actions]
        assert "critical" in priorities or "high" in priorities

    def test_stats_tracking(self, model_manager, sample_features):
        """Test that prediction stats are tracked."""
        initial_count = model_manager.stats["prediction_count"]

        # Make some predictions
        model_manager.predict(sample_features)
        model_manager.predict(sample_features)

        stats = model_manager.stats
        assert stats["prediction_count"] == initial_count + 2
        assert stats["avg_latency_ms"] >= 0
        assert stats["last_prediction_at"] is not None


class TestFeatureVector:
    """Tests for feature vector generation."""

    def test_feature_vector_length(self, sample_features):
        """Test feature vector has correct length."""
        vector = sample_features.to_feature_vector()
        assert len(vector) == 22  # Total features

    def test_feature_vector_order(self, sample_features):
        """Test feature vector is in correct order."""
        vector = sample_features.to_feature_vector()

        # First 7 should be client behavioral
        assert vector[0] == sample_features.client_historical_noshow_rate
        assert vector[6] == 1.0  # client_has_payment_method (True -> 1.0)

        # Check some appointment context features
        assert vector[7] == float(sample_features.booking_lead_days)
        assert vector[8] == float(sample_features.day_of_week)

    def test_lifecycle_encoding(self):
        """Test lifecycle stage encoding matches Flutter."""
        features_new = PredictionFeaturesRequest(
            appointment_id="test",
            business_id="test",
            feature_schema_version=1,
            client_historical_noshow_rate=0.0,
            client_historical_cancel_rate=0.0,
            client_total_appointments=0,
            client_days_since_last_visit=0,
            client_lifetime_value_cents=0,
            client_lifecycle_stage="newClient",  # Should encode to 0.0
            client_has_payment_method=False,
            booking_lead_days=0,
            day_of_week=1,
            hour_of_day=9,
            is_recurring=False,
            is_group_session=False,
            service_duration_minutes=30,
            service_price_cents=0,
            requires_payment=False,
            payment_collected=False,
            has_intake_form=False,
            provider_historical_noshow_rate=0.0,
            provider_total_appointments=0,
            slot_historical_noshow_rate=0.0,
            is_first_appointment_of_day=False,
            is_last_appointment_of_day=False,
        )

        vector = features_new.to_feature_vector()
        assert vector[5] == 0.0  # newClient -> 0.0

        # Test other lifecycle stages
        features_active = PredictionFeaturesRequest(**{
            **features_new.model_dump(),
            "client_lifecycle_stage": "active"
        })
        vector_active = features_active.to_feature_vector()
        assert vector_active[5] == 1.0  # active -> 1.0

        features_inactive = PredictionFeaturesRequest(**{
            **features_new.model_dump(),
            "client_lifecycle_stage": "inactive"
        })
        vector_inactive = features_inactive.to_feature_vector()
        assert vector_inactive[5] == 2.0  # inactive -> 2.0

        features_churned = PredictionFeaturesRequest(**{
            **features_new.model_dump(),
            "client_lifecycle_stage": "churned"
        })
        vector_churned = features_churned.to_feature_vector()
        assert vector_churned[5] == 3.0  # churned -> 3.0

    def test_boolean_encoding(self, sample_features):
        """Test boolean fields encode correctly."""
        vector = sample_features.to_feature_vector()

        # client_has_payment_method is True -> 1.0
        assert vector[6] == 1.0

        # Create with False
        features_no_payment = PredictionFeaturesRequest(**{
            **sample_features.model_dump(),
            "client_has_payment_method": False
        })
        vector_no_payment = features_no_payment.to_feature_vector()
        assert vector_no_payment[6] == 0.0
