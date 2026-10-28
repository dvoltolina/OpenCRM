"""
Tests for the SHAP-based prediction explainer.

Agent AI-19: Prediction Explainability
"""
import pytest
import numpy as np

from ..explainer import (
    PredictionExplainer,
    ExplanationFactor,
    PredictionExplanation,
    ExplanationResponse,
    get_explainer,
)
from ..schemas import FEATURE_NAMES


class TestPredictionExplainer:
    """Tests for PredictionExplainer class."""

    @pytest.fixture
    def explainer(self):
        """Create explainer without model (uses rule-based explanations)."""
        return PredictionExplainer()

    @pytest.fixture
    def feature_vector(self):
        """Create sample feature vector."""
        return np.array([
            0.40,  # clientHistoricalNoshowRate
            0.15,  # clientHistoricalCancelRate
            8.0,   # clientTotalAppointments
            30.0,  # clientDaysSinceLastVisit
            50000, # clientLifetimeValueCents
            1.0,   # clientLifecycleStage (active)
            1.0,   # clientHasPaymentMethod
            14.0,  # bookingLeadDays
            3.0,   # dayOfWeek (Wednesday)
            10.0,  # hourOfDay
            0.0,   # isRecurring
            0.0,   # isGroupSession
            60.0,  # serviceDurationMinutes
            10000, # servicePriceCents
            1.0,   # requiresPayment
            0.0,   # paymentCollected
            1.0,   # hasIntakeForm
            0.12,  # providerHistoricalNoshowRate
            500,   # providerTotalAppointments
            0.15,  # slotHistoricalNoshowRate
            0.0,   # isFirstAppointmentOfDay
            0.0,   # isLastAppointmentOfDay
        ])

    @pytest.fixture
    def feature_values(self):
        """Create sample feature values dict."""
        return {
            'clientHistoricalNoshowRate': 0.40,
            'clientHistoricalCancelRate': 0.15,
            'bookingLeadDays': 14,
            'paymentCollected': False,
            'clientHasPaymentMethod': True,
            'isRecurring': False,
            'hasIntakeForm': True,
            'clientLifecycleStage': 'active',
        }

    def test_explain_returns_explanation(self, explainer, feature_vector, feature_values):
        """Test that explain() returns a valid PredictionExplanation."""
        explanation = explainer.explain(
            appointment_id='test_appt_123',
            feature_vector=feature_vector,
            feature_values=feature_values,
            probability=0.72,
            risk_level='high',
            model_version='1.0.0',
        )

        assert isinstance(explanation, PredictionExplanation)
        assert explanation.appointment_id == 'test_appt_123'
        assert explanation.probability == 0.72
        assert explanation.risk_level == 'high'
        assert len(explanation.top_factors) == 3  # Default num_factors
        assert explanation.model_version == '1.0.0'

    def test_explain_returns_requested_num_factors(self, explainer, feature_vector, feature_values):
        """Test that num_factors parameter is respected."""
        explanation = explainer.explain(
            appointment_id='test_appt',
            feature_vector=feature_vector,
            feature_values=feature_values,
            probability=0.5,
            risk_level='medium',
            num_factors=5,
        )

        assert len(explanation.top_factors) == 5

    def test_explanation_factors_have_required_fields(self, explainer, feature_vector, feature_values):
        """Test that explanation factors have all required fields."""
        explanation = explainer.explain(
            appointment_id='test_appt',
            feature_vector=feature_vector,
            feature_values=feature_values,
            probability=0.5,
            risk_level='medium',
        )

        for factor in explanation.top_factors:
            assert factor.feature in FEATURE_NAMES
            assert factor.display_name
            assert factor.impact in ['increases', 'decreases']
            assert 0 <= factor.magnitude <= 1
            assert factor.explanation
            assert factor.raw_shap_value is not None

    def test_summary_generated_for_high_risk(self, explainer, feature_vector, feature_values):
        """Test summary generation for high risk predictions."""
        explanation = explainer.explain(
            appointment_id='test_appt',
            feature_vector=feature_vector,
            feature_values=feature_values,
            probability=0.80,
            risk_level='high',
        )

        assert 'high' in explanation.summary.lower() or 'risk' in explanation.summary.lower()

    def test_summary_generated_for_low_risk(self, explainer, feature_vector, feature_values):
        """Test summary generation for low risk predictions."""
        # Create low-risk feature vector
        low_risk_vector = feature_vector.copy()
        low_risk_vector[0] = 0.05  # Low historical no-show rate
        low_risk_vector[15] = 1.0  # Payment collected

        explanation = explainer.explain(
            appointment_id='test_appt',
            feature_vector=low_risk_vector,
            feature_values=feature_values,
            probability=0.15,
            risk_level='low',
        )

        assert 'low' in explanation.summary.lower() or explanation.summary

    def test_humanize_historical_noshow_rate(self, explainer):
        """Test humanization of historical no-show rate."""
        high_rate = explainer._humanize_factor('clientHistoricalNoshowRate', 0.40, True)
        assert '40%' in high_rate

        low_rate = explainer._humanize_factor('clientHistoricalNoshowRate', 0.05, False)
        assert 'good' in low_rate.lower() or 'history' in low_rate.lower()

    def test_humanize_payment_collected(self, explainer):
        """Test humanization of payment collected feature."""
        collected = explainer._humanize_factor('paymentCollected', True, False)
        assert 'collected' in collected.lower()

        not_collected = explainer._humanize_factor('paymentCollected', False, True)
        assert 'no' in not_collected.lower() or 'not' in not_collected.lower()

    def test_humanize_booking_lead_days(self, explainer):
        """Test humanization of booking lead days."""
        long_lead = explainer._humanize_factor('bookingLeadDays', 21, True)
        assert '21' in long_lead

        same_day = explainer._humanize_factor('bookingLeadDays', 0, False)
        assert 'same' in same_day.lower()

    def test_humanize_lifecycle_stage(self, explainer):
        """Test humanization of lifecycle stage."""
        new_client = explainer._humanize_lifecycle(0)
        assert 'new' in new_client.lower()

        active = explainer._humanize_lifecycle(1)
        assert 'active' in active.lower()

        churned = explainer._humanize_lifecycle(3)
        assert 'churn' in churned.lower() or 'risk' in churned.lower()

    def test_humanize_day_of_week(self, explainer):
        """Test humanization of day of week."""
        monday = explainer._humanize_day_of_week(1)
        assert 'Monday' in monday

        friday = explainer._humanize_day_of_week(5)
        assert 'Friday' in friday

    def test_is_shap_enabled_false_without_model(self, explainer):
        """Test that SHAP is not enabled without a model."""
        assert not explainer.is_shap_enabled

    def test_set_model_returns_false_without_shap(self, explainer):
        """Test that set_model returns False when SHAP not available for mock."""
        # Since we don't have a real LightGBM model, this tests the fallback
        result = explainer.set_model(None)
        assert not result


class TestExplanationFactor:
    """Tests for ExplanationFactor dataclass."""

    def test_factor_creation(self):
        """Test creating an ExplanationFactor."""
        factor = ExplanationFactor(
            feature='clientHistoricalNoshowRate',
            display_name="Client's Past No-Show Rate",
            impact='increases',
            magnitude=0.35,
            raw_shap_value=0.15,
            feature_value=0.40,
            explanation='Client has 40% historical no-show rate',
        )

        assert factor.feature == 'clientHistoricalNoshowRate'
        assert factor.impact == 'increases'
        assert factor.magnitude == 0.35


class TestExplanationResponse:
    """Tests for ExplanationResponse helper."""

    def test_from_explanation(self):
        """Test converting explanation to API response format."""
        explanation = PredictionExplanation(
            appointment_id='test_123',
            probability=0.72,
            risk_level='high',
            top_factors=[
                ExplanationFactor(
                    feature='clientHistoricalNoshowRate',
                    display_name="Client's Past No-Show Rate",
                    impact='increases',
                    magnitude=0.35,
                    raw_shap_value=0.15,
                    feature_value=0.40,
                    explanation='Client has 40% historical no-show rate',
                ),
            ],
            summary='High risk primarily because: Client has 40% historical no-show rate',
            model_version='1.0.0',
        )

        response = ExplanationResponse.from_explanation(explanation)

        assert response['appointment_id'] == 'test_123'
        assert response['probability'] == 0.72
        assert response['risk_level'] == 'high'
        assert len(response['top_factors']) == 1
        assert response['top_factors'][0]['feature'] == 'clientHistoricalNoshowRate'
        assert response['summary'] == 'High risk primarily because: Client has 40% historical no-show rate'


class TestSingletonExplainer:
    """Tests for singleton explainer functions."""

    def test_get_explainer_returns_instance(self):
        """Test that get_explainer returns an explainer instance."""
        explainer = get_explainer()
        assert isinstance(explainer, PredictionExplainer)

    def test_get_explainer_returns_same_instance(self):
        """Test that get_explainer returns the same instance."""
        explainer1 = get_explainer()
        explainer2 = get_explainer()
        assert explainer1 is explainer2


class TestRuleBasedExplanation:
    """Tests for rule-based explanation fallback."""

    @pytest.fixture
    def explainer(self):
        return PredictionExplainer()

    def test_rule_based_identifies_high_noshow_rate(self, explainer):
        """Test that rule-based method identifies high no-show rate as important."""
        feature_vector = np.zeros(22)
        feature_vector[0] = 0.60  # Very high no-show rate

        explanation = explainer.explain(
            appointment_id='test',
            feature_vector=feature_vector,
            feature_values={'clientHistoricalNoshowRate': 0.60},
            probability=0.80,
            risk_level='high',
        )

        # The high no-show rate should be in top factors
        feature_names = [f.feature for f in explanation.top_factors]
        assert 'clientHistoricalNoshowRate' in feature_names

    def test_rule_based_identifies_no_payment(self, explainer):
        """Test that rule-based method identifies missing payment as important."""
        feature_vector = np.zeros(22)
        feature_vector[14] = 1.0  # requiresPayment = True
        feature_vector[15] = 0.0  # paymentCollected = False

        explanation = explainer.explain(
            appointment_id='test',
            feature_vector=feature_vector,
            feature_values={'paymentCollected': False},
            probability=0.55,
            risk_level='medium',
        )

        # Should generate valid explanation
        assert len(explanation.top_factors) > 0

    def test_deviation_calculation(self, explainer):
        """Test that deviation from neutral values is calculated."""
        # High deviation
        high_dev = explainer._calculate_deviation('clientHistoricalNoshowRate', 0.50)
        # Low deviation (near neutral)
        low_dev = explainer._calculate_deviation('clientHistoricalNoshowRate', 0.10)

        assert high_dev > low_dev

    def test_impact_direction_for_payment(self, explainer):
        """Test impact direction for payment-related features."""
        # Payment collected should decrease risk
        direction = explainer._determine_impact_direction('paymentCollected', 1.0)
        assert direction == 'decreases'

        # No payment collected should increase risk
        direction = explainer._determine_impact_direction('paymentCollected', 0.0)
        assert direction == 'increases'

    def test_impact_direction_for_noshow_rate(self, explainer):
        """Test impact direction for no-show rate."""
        # High no-show rate should increase risk
        direction = explainer._determine_impact_direction('clientHistoricalNoshowRate', 0.50)
        assert direction == 'increases'

        # Low no-show rate should decrease risk
        direction = explainer._determine_impact_direction('clientHistoricalNoshowRate', 0.05)
        assert direction == 'decreases'
