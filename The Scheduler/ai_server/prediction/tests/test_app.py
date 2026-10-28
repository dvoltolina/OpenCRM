"""
Tests for prediction service API.
Run with: pytest tests/ -v

Agent AI-3: Python Prediction Server
"""
import pytest
from fastapi.testclient import TestClient

from ..app import app, model_manager


client = TestClient(app)


@pytest.fixture
def sample_features():
    """Create sample feature request for testing."""
    return {
        "appointment_id": "test_appt_123",
        "business_id": "test_business_456",
        "feature_schema_version": 1,
        "client_historical_noshow_rate": 0.15,
        "client_historical_cancel_rate": 0.10,
        "client_total_appointments": 8,
        "client_days_since_last_visit": 30,
        "client_lifetime_value_cents": 50000,
        "client_lifecycle_stage": "active",
        "client_has_payment_method": True,
        "booking_lead_days": 7,
        "day_of_week": 2,
        "hour_of_day": 14,
        "is_recurring": False,
        "is_group_session": False,
        "service_duration_minutes": 60,
        "service_price_cents": 10000,
        "requires_payment": True,
        "payment_collected": True,
        "has_intake_form": True,
        "provider_historical_noshow_rate": 0.08,
        "provider_total_appointments": 500,
        "slot_historical_noshow_rate": 0.12,
        "is_first_appointment_of_day": False,
        "is_last_appointment_of_day": False,
    }


@pytest.fixture
def high_risk_features():
    """Create features that should result in high risk prediction."""
    return {
        "appointment_id": "test_appt_high_risk",
        "business_id": "test_business_456",
        "feature_schema_version": 1,
        "client_historical_noshow_rate": 0.6,  # High no-show history
        "client_historical_cancel_rate": 0.4,  # High cancel history
        "client_total_appointments": 3,
        "client_days_since_last_visit": 90,
        "client_lifetime_value_cents": 5000,
        "client_lifecycle_stage": "inactive",
        "client_has_payment_method": False,  # No payment method
        "booking_lead_days": 21,  # Long lead time
        "day_of_week": 1,
        "hour_of_day": 8,
        "is_recurring": False,
        "is_group_session": False,
        "service_duration_minutes": 30,
        "service_price_cents": 5000,
        "requires_payment": True,
        "payment_collected": False,  # No payment collected
        "has_intake_form": False,
        "provider_historical_noshow_rate": 0.15,
        "provider_total_appointments": 100,
        "slot_historical_noshow_rate": 0.25,
        "is_first_appointment_of_day": True,
        "is_last_appointment_of_day": False,
    }


class TestHealthEndpoints:
    """Tests for health check endpoints."""

    def test_liveness(self):
        """Test liveness probe returns alive."""
        response = client.get("/health/live")
        assert response.status_code == 200
        assert response.json()["status"] == "alive"

    def test_health_check(self):
        """Test detailed health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "model_loaded" in data
        assert "uptime_seconds" in data

    def test_readiness(self):
        """Test readiness probe."""
        response = client.get("/health/ready")
        # May return 200 or 503 depending on model state
        assert response.status_code in [200, 503]


class TestPredictionEndpoints:
    """Tests for prediction endpoints."""

    def test_predict_noshow_success(self, sample_features):
        """Test successful prediction with versioned API."""
        response = client.post("/api/v1/predict/noshow", json=sample_features)

        # May fail if model not loaded - that's expected in CI without model
        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200
        data = response.json()

        assert data["appointment_id"] == "test_appt_123"
        assert 0 <= data["probability"] <= 1
        assert data["risk_level"] in ["high", "medium", "low", "unknown"]
        assert 0 <= data["confidence"] <= 1
        assert isinstance(data["recommended_actions"], list)
        assert isinstance(data["top_features"], list)
        assert "model_version" in data
        assert "predicted_at" in data
        assert "expires_at" in data

    def test_predict_noshow_legacy_endpoint(self, sample_features):
        """Test legacy endpoint still works."""
        response = client.post("/predict/noshow", json=sample_features)

        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200

    def test_predict_noshow_validation_error(self):
        """Test validation of invalid features."""
        invalid_features = {
            "appointment_id": "test",
            "business_id": "test",
            "client_historical_noshow_rate": 1.5,  # Invalid: > 1.0
        }

        response = client.post("/api/v1/predict/noshow", json=invalid_features)
        assert response.status_code == 422  # Validation error

    def test_predict_high_risk(self, high_risk_features):
        """Test that high-risk features result in high/medium risk level."""
        response = client.post("/api/v1/predict/noshow", json=high_risk_features)

        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200
        data = response.json()

        # With mock model, high-risk features should produce elevated probability
        assert data["probability"] > 0.3
        # Should have recommended actions
        assert len(data["recommended_actions"]) > 0

    def test_batch_prediction(self, sample_features):
        """Test batch prediction endpoint."""
        request_data = {
            "appointments": [sample_features, sample_features]
        }

        response = client.post("/api/v1/predict/noshow/batch", json=request_data)

        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200
        data = response.json()

        assert data["total_processed"] == 2
        assert len(data["predictions"]) == 2
        assert "processing_time_ms" in data

    def test_batch_prediction_empty(self):
        """Test batch prediction with empty list."""
        request_data = {"appointments": []}

        response = client.post("/api/v1/predict/noshow/batch", json=request_data)

        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200
        data = response.json()
        assert data["total_processed"] == 0


class TestFeatureValidation:
    """Tests for feature schema validation."""

    def test_lifecycle_stage_validation(self, sample_features):
        """Test that lifecycle stage is validated."""
        sample_features["client_lifecycle_stage"] = "invalid_stage"

        response = client.post("/api/v1/predict/noshow", json=sample_features)
        assert response.status_code == 422

    def test_probability_bounds(self, sample_features):
        """Test that rates must be 0-1."""
        sample_features["client_historical_noshow_rate"] = -0.1

        response = client.post("/api/v1/predict/noshow", json=sample_features)
        assert response.status_code == 422

    def test_day_of_week_bounds(self, sample_features):
        """Test day of week validation."""
        sample_features["day_of_week"] = 8  # Invalid: must be 1-7

        response = client.post("/api/v1/predict/noshow", json=sample_features)
        assert response.status_code == 422

    def test_hour_of_day_bounds(self, sample_features):
        """Test hour of day validation."""
        sample_features["hour_of_day"] = 24  # Invalid: must be 0-23

        response = client.post("/api/v1/predict/noshow", json=sample_features)
        assert response.status_code == 422

    def test_valid_lifecycle_stages(self, sample_features):
        """Test all valid lifecycle stages work."""
        valid_stages = ["newClient", "active", "inactive", "churned"]

        for stage in valid_stages:
            sample_features["client_lifecycle_stage"] = stage
            response = client.post("/api/v1/predict/noshow", json=sample_features)

            if response.status_code == 503:
                pytest.skip("Model not loaded - expected in CI")

            assert response.status_code == 200, f"Failed for stage: {stage}"


class TestModelManagement:
    """Tests for model management endpoints."""

    def test_get_model_metadata(self):
        """Test getting model metadata."""
        response = client.get("/model/metadata")

        if response.status_code == 503:
            pytest.skip("Model not loaded - expected in CI")

        assert response.status_code == 200
        data = response.json()
        assert "model_id" in data
        assert "version" in data
        assert "feature_names" in data

    def test_reload_model(self):
        """Test model reload endpoint."""
        response = client.post("/model/reload")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "reload_initiated"
