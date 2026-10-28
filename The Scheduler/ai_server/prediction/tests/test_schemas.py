"""
Tests for Pydantic schema validation.
Run with: pytest tests/test_schemas.py -v

Agent AI-3: Python Prediction Server
"""
import pytest
from pydantic import ValidationError

from ..schemas import (
    PredictionFeaturesRequest,
    NoshowPredictionResponse,
    RiskLevel,
    ActionPriority,
    FEATURE_NAMES,
    FEATURE_DISPLAY_NAMES,
)


class TestPredictionFeaturesRequest:
    """Tests for PredictionFeaturesRequest schema."""

    @pytest.fixture
    def valid_features(self):
        """Valid feature request data."""
        return {
            "appointment_id": "appt_123",
            "business_id": "biz_456",
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

    def test_valid_request_parses(self, valid_features):
        """Test that valid data parses without error."""
        request = PredictionFeaturesRequest(**valid_features)
        assert request.appointment_id == "appt_123"
        assert request.client_historical_noshow_rate == 0.15

    def test_rate_upper_bound(self, valid_features):
        """Test rate fields reject values > 1.0."""
        valid_features["client_historical_noshow_rate"] = 1.1
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_rate_lower_bound(self, valid_features):
        """Test rate fields reject negative values."""
        valid_features["client_historical_noshow_rate"] = -0.1
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_rate_boundary_values(self, valid_features):
        """Test rate fields accept boundary values."""
        valid_features["client_historical_noshow_rate"] = 0.0
        request1 = PredictionFeaturesRequest(**valid_features)
        assert request1.client_historical_noshow_rate == 0.0

        valid_features["client_historical_noshow_rate"] = 1.0
        request2 = PredictionFeaturesRequest(**valid_features)
        assert request2.client_historical_noshow_rate == 1.0

    def test_day_of_week_validation(self, valid_features):
        """Test day_of_week must be 1-7."""
        valid_features["day_of_week"] = 0
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

        valid_features["day_of_week"] = 8
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_day_of_week_valid_values(self, valid_features):
        """Test all valid day_of_week values."""
        for day in range(1, 8):
            valid_features["day_of_week"] = day
            request = PredictionFeaturesRequest(**valid_features)
            assert request.day_of_week == day

    def test_hour_of_day_validation(self, valid_features):
        """Test hour_of_day must be 0-23."""
        valid_features["hour_of_day"] = -1
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

        valid_features["hour_of_day"] = 24
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_hour_of_day_valid_values(self, valid_features):
        """Test boundary hour values."""
        valid_features["hour_of_day"] = 0
        request1 = PredictionFeaturesRequest(**valid_features)
        assert request1.hour_of_day == 0

        valid_features["hour_of_day"] = 23
        request2 = PredictionFeaturesRequest(**valid_features)
        assert request2.hour_of_day == 23

    def test_lifecycle_stage_validation(self, valid_features):
        """Test lifecycle_stage must be valid enum."""
        valid_features["client_lifecycle_stage"] = "invalid"
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_lifecycle_stage_case_insensitive(self, valid_features):
        """Test lifecycle_stage is case insensitive."""
        stages = ["newClient", "NEWCLIENT", "NewClient", "newclient"]
        for stage in stages:
            valid_features["client_lifecycle_stage"] = stage
            request = PredictionFeaturesRequest(**valid_features)
            assert request.client_lifecycle_stage == "newclient"

    def test_booking_lead_days_max(self, valid_features):
        """Test booking_lead_days has max of 365."""
        valid_features["booking_lead_days"] = 366
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_service_duration_min(self, valid_features):
        """Test service_duration_minutes must be >= 1."""
        valid_features["service_duration_minutes"] = 0
        with pytest.raises(ValidationError):
            PredictionFeaturesRequest(**valid_features)

    def test_count_fields_non_negative(self, valid_features):
        """Test count fields must be non-negative."""
        count_fields = [
            "client_total_appointments",
            "client_days_since_last_visit",
            "client_lifetime_value_cents",
            "provider_total_appointments",
            "service_price_cents",
        ]

        for field in count_fields:
            test_data = valid_features.copy()
            test_data[field] = -1
            with pytest.raises(ValidationError):
                PredictionFeaturesRequest(**test_data)


class TestFeatureVector:
    """Tests for feature vector generation."""

    @pytest.fixture
    def request(self):
        """Create a request object for testing."""
        return PredictionFeaturesRequest(
            appointment_id="test",
            business_id="test",
            feature_schema_version=1,
            client_historical_noshow_rate=0.25,
            client_historical_cancel_rate=0.15,
            client_total_appointments=10,
            client_days_since_last_visit=14,
            client_lifetime_value_cents=75000,
            client_lifecycle_stage="active",
            client_has_payment_method=True,
            booking_lead_days=5,
            day_of_week=3,
            hour_of_day=10,
            is_recurring=True,
            is_group_session=False,
            service_duration_minutes=45,
            service_price_cents=8000,
            requires_payment=True,
            payment_collected=False,
            has_intake_form=True,
            provider_historical_noshow_rate=0.05,
            provider_total_appointments=200,
            slot_historical_noshow_rate=0.08,
            is_first_appointment_of_day=True,
            is_last_appointment_of_day=False,
        )

    def test_vector_length_matches_feature_names(self, request):
        """Test vector length matches FEATURE_NAMES constant."""
        vector = request.to_feature_vector()
        assert len(vector) == len(FEATURE_NAMES)

    def test_vector_values_correct(self, request):
        """Test specific vector values are correct."""
        vector = request.to_feature_vector()

        # Index 0: client_historical_noshow_rate
        assert vector[0] == 0.25

        # Index 5: client_lifecycle_stage (active = 1.0)
        assert vector[5] == 1.0

        # Index 6: client_has_payment_method (True = 1.0)
        assert vector[6] == 1.0

        # Index 10: is_recurring (True = 1.0)
        assert vector[10] == 1.0

        # Index 15: payment_collected (False = 0.0)
        assert vector[15] == 0.0


class TestFeatureConstants:
    """Tests for feature name constants."""

    def test_feature_names_count(self):
        """Test we have exactly 22 features."""
        assert len(FEATURE_NAMES) == 22

    def test_all_features_have_display_names(self):
        """Test all features have display names."""
        for name in FEATURE_NAMES:
            assert name in FEATURE_DISPLAY_NAMES, f"Missing display name for {name}"

    def test_feature_names_match_flutter(self):
        """Test feature names match Flutter PredictionFeatures.featureNames."""
        expected = [
            "clientHistoricalNoshowRate",
            "clientHistoricalCancelRate",
            "clientTotalAppointments",
            "clientDaysSinceLastVisit",
            "clientLifetimeValueCents",
            "clientLifecycleStage",
            "clientHasPaymentMethod",
            "bookingLeadDays",
            "dayOfWeek",
            "hourOfDay",
            "isRecurring",
            "isGroupSession",
            "serviceDurationMinutes",
            "servicePriceCents",
            "requiresPayment",
            "paymentCollected",
            "hasIntakeForm",
            "providerHistoricalNoshowRate",
            "providerTotalAppointments",
            "slotHistoricalNoshowRate",
            "isFirstAppointmentOfDay",
            "isLastAppointmentOfDay",
        ]
        assert FEATURE_NAMES == expected


class TestEnums:
    """Tests for enum values."""

    def test_risk_level_values(self):
        """Test RiskLevel enum values match Flutter."""
        assert RiskLevel.HIGH.value == "high"
        assert RiskLevel.MEDIUM.value == "medium"
        assert RiskLevel.LOW.value == "low"
        assert RiskLevel.UNKNOWN.value == "unknown"

    def test_action_priority_values(self):
        """Test ActionPriority enum values match Flutter."""
        assert ActionPriority.CRITICAL.value == "critical"
        assert ActionPriority.HIGH.value == "high"
        assert ActionPriority.MEDIUM.value == "medium"
        assert ActionPriority.LOW.value == "low"
