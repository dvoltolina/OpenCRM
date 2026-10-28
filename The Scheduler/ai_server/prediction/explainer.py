"""
SHAP-based prediction explainability module.

Provides human-readable explanations for no-show predictions using
SHAP (SHapley Additive exPlanations) values to identify which features
contributed most to each prediction.

Agent AI-19: Prediction Explainability
"""
import logging
from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from functools import lru_cache

import numpy as np

try:
    import shap
    SHAP_AVAILABLE = True
except ImportError:
    SHAP_AVAILABLE = False
    shap = None

from .schemas import (
    FEATURE_NAMES,
    FEATURE_DISPLAY_NAMES,
)

logger = logging.getLogger(__name__)


@dataclass
class ExplanationFactor:
    """A single factor contributing to a prediction."""
    feature: str
    display_name: str
    impact: str  # "increases" or "decreases"
    magnitude: float  # Absolute SHAP value (0-1 normalized)
    raw_shap_value: float
    feature_value: Any
    explanation: str  # Human-readable explanation


@dataclass
class PredictionExplanation:
    """Complete explanation for a prediction."""
    appointment_id: str
    probability: float
    risk_level: str
    top_factors: List[ExplanationFactor]
    summary: str
    model_version: str
    explanation_version: str = "1.0.0"


class PredictionExplainer:
    """
    SHAP-based explainer for no-show predictions.

    Uses TreeExplainer for LightGBM models to compute feature
    contributions, then humanizes them for staff understanding.

    Key principles:
    - Top 3 factors only (avoid information overload)
    - Human-readable explanations (not raw feature names)
    - Direction matters (increases vs decreases risk)
    """

    def __init__(self, model=None):
        """
        Initialize explainer with optional model.

        Args:
            model: LightGBM Booster model. If None, uses rule-based explanations.
        """
        self._model = model
        self._shap_explainer: Optional[Any] = None
        self._use_shap = False

        if model is not None and SHAP_AVAILABLE:
            try:
                self._shap_explainer = shap.TreeExplainer(model)
                self._use_shap = True
                logger.info("SHAP TreeExplainer initialized successfully")
            except Exception as e:
                logger.warning(f"Failed to create SHAP explainer: {e}")
                self._use_shap = False
        elif not SHAP_AVAILABLE:
            logger.info("SHAP not available, using rule-based explanations")

    def set_model(self, model) -> bool:
        """
        Update the model used for explanations.

        Args:
            model: LightGBM Booster model

        Returns:
            True if SHAP explainer was created successfully
        """
        self._model = model
        if model is not None and SHAP_AVAILABLE:
            try:
                self._shap_explainer = shap.TreeExplainer(model)
                self._use_shap = True
                return True
            except Exception as e:
                logger.warning(f"Failed to create SHAP explainer: {e}")
        self._use_shap = False
        return False

    def explain(
        self,
        appointment_id: str,
        feature_vector: np.ndarray,
        feature_values: Dict[str, Any],
        probability: float,
        risk_level: str,
        model_version: str = "unknown",
        num_factors: int = 3,
    ) -> PredictionExplanation:
        """
        Generate explanation for a prediction.

        Args:
            appointment_id: Unique appointment ID
            feature_vector: Numeric feature array (22 features)
            feature_values: Original feature values (for display)
            probability: Predicted no-show probability
            risk_level: "high", "medium", or "low"
            model_version: Model version string
            num_factors: Number of top factors to return (default 3)

        Returns:
            PredictionExplanation with top contributing factors
        """
        if self._use_shap and self._shap_explainer is not None:
            factors = self._explain_with_shap(
                feature_vector, feature_values, probability, num_factors
            )
        else:
            factors = self._explain_rule_based(
                feature_vector, feature_values, probability, num_factors
            )

        # Generate summary
        summary = self._generate_summary(factors, probability, risk_level)

        return PredictionExplanation(
            appointment_id=appointment_id,
            probability=probability,
            risk_level=risk_level,
            top_factors=factors,
            summary=summary,
            model_version=model_version,
        )

    def _explain_with_shap(
        self,
        feature_vector: np.ndarray,
        feature_values: Dict[str, Any],
        probability: float,
        num_factors: int,
    ) -> List[ExplanationFactor]:
        """Generate explanation using SHAP values."""
        try:
            # Compute SHAP values
            shap_values = self._shap_explainer.shap_values(
                feature_vector.reshape(1, -1)
            )[0]

            # Normalize SHAP values for magnitude comparison
            max_shap = max(abs(shap_values.max()), abs(shap_values.min()), 1e-6)

            # Build factors list
            factors = []
            for i, (name, shap_val) in enumerate(zip(FEATURE_NAMES, shap_values)):
                raw_value = feature_values.get(name, feature_vector[i])
                display_name = FEATURE_DISPLAY_NAMES.get(name, name)

                factor = ExplanationFactor(
                    feature=name,
                    display_name=display_name,
                    impact="increases" if shap_val > 0 else "decreases",
                    magnitude=abs(shap_val) / max_shap,
                    raw_shap_value=float(shap_val),
                    feature_value=raw_value,
                    explanation=self._humanize_factor(name, raw_value, shap_val > 0),
                )
                factors.append(factor)

            # Sort by absolute SHAP value and return top N
            factors.sort(key=lambda f: abs(f.raw_shap_value), reverse=True)
            return factors[:num_factors]

        except Exception as e:
            logger.error(f"SHAP explanation failed: {e}")
            return self._explain_rule_based(
                feature_vector, feature_values, probability, num_factors
            )

    def _explain_rule_based(
        self,
        feature_vector: np.ndarray,
        feature_values: Dict[str, Any],
        probability: float,
        num_factors: int,
    ) -> List[ExplanationFactor]:
        """
        Generate explanation using rule-based importance.
        Fallback when SHAP is not available.
        """
        # Feature importance based on domain knowledge
        importance_weights = {
            'clientHistoricalNoshowRate': 0.25,
            'clientHistoricalCancelRate': 0.12,
            'bookingLeadDays': 0.15,
            'paymentCollected': 0.12,
            'clientHasPaymentMethod': 0.08,
            'isRecurring': 0.06,
            'clientLifecycleStage': 0.05,
            'slotHistoricalNoshowRate': 0.04,
            'providerHistoricalNoshowRate': 0.03,
            'clientTotalAppointments': 0.03,
            'clientDaysSinceLastVisit': 0.02,
            'hasIntakeForm': 0.02,
        }

        factors = []
        for i, name in enumerate(FEATURE_NAMES):
            value = feature_vector[i] if i < len(feature_vector) else 0.0
            raw_value = feature_values.get(name, value)
            display_name = FEATURE_DISPLAY_NAMES.get(name, name)

            # Calculate pseudo-SHAP based on value deviation from neutral
            base_importance = importance_weights.get(name, 0.01)
            impact_direction = self._determine_impact_direction(name, value)

            # Scale importance by how much the feature deviates
            deviation = self._calculate_deviation(name, value)
            pseudo_shap = base_importance * deviation * (1 if impact_direction == "increases" else -1)

            factor = ExplanationFactor(
                feature=name,
                display_name=display_name,
                impact=impact_direction,
                magnitude=base_importance * deviation,
                raw_shap_value=pseudo_shap,
                feature_value=raw_value,
                explanation=self._humanize_factor(name, raw_value, impact_direction == "increases"),
            )
            factors.append(factor)

        # Sort by magnitude and return top N
        factors.sort(key=lambda f: f.magnitude, reverse=True)
        return factors[:num_factors]

    def _determine_impact_direction(self, feature_name: str, value: float) -> str:
        """Determine if a feature value increases or decreases risk."""
        # Features where higher values decrease risk
        decreases_when_high = {
            'paymentCollected', 'clientHasPaymentMethod', 'hasIntakeForm',
            'isRecurring', 'clientTotalAppointments'
        }

        # Features where higher values increase risk
        increases_when_high = {
            'clientHistoricalNoshowRate', 'clientHistoricalCancelRate',
            'bookingLeadDays', 'slotHistoricalNoshowRate',
            'providerHistoricalNoshowRate', 'clientDaysSinceLastVisit'
        }

        if feature_name in decreases_when_high:
            return "decreases" if value > 0.5 else "increases"
        elif feature_name in increases_when_high:
            return "increases" if value > 0.2 else "decreases"
        else:
            return "increases"  # Default assumption

    def _calculate_deviation(self, feature_name: str, value: float) -> float:
        """Calculate how much a feature deviates from neutral/average."""
        # Approximate neutral values
        neutral_values = {
            'clientHistoricalNoshowRate': 0.1,
            'clientHistoricalCancelRate': 0.1,
            'bookingLeadDays': 7.0,
            'paymentCollected': 0.5,
            'clientHasPaymentMethod': 0.5,
            'isRecurring': 0.5,
            'slotHistoricalNoshowRate': 0.1,
            'providerHistoricalNoshowRate': 0.1,
            'clientDaysSinceLastVisit': 30.0,
            'clientTotalAppointments': 5.0,
        }

        neutral = neutral_values.get(feature_name, 0.5)

        # Normalize deviation to 0-1 range
        if feature_name in ['bookingLeadDays']:
            deviation = min(abs(value - neutral) / 30.0, 1.0)
        elif feature_name in ['clientDaysSinceLastVisit']:
            deviation = min(abs(value - neutral) / 90.0, 1.0)
        elif feature_name in ['clientTotalAppointments']:
            deviation = min(abs(value - neutral) / 20.0, 1.0)
        else:
            deviation = min(abs(value - neutral) * 2.0, 1.0)

        return max(deviation, 0.1)  # Minimum deviation for relevance

    def _humanize_factor(
        self,
        feature_name: str,
        value: Any,
        increases_risk: bool,
    ) -> str:
        """
        Generate human-readable explanation for a factor.

        Examples:
        - "Client has 40% historical no-show rate"
        - "No deposit collected"
        - "Booked 21 days in advance"
        """
        explanations = {
            'clientHistoricalNoshowRate': lambda v: (
                f"Client has {int(v * 100)}% historical no-show rate"
                if v > 0.1 else "Client has good attendance history"
            ),
            'clientHistoricalCancelRate': lambda v: (
                f"Client has {int(v * 100)}% cancellation rate"
                if v > 0.1 else "Client rarely cancels"
            ),
            'bookingLeadDays': lambda v: (
                f"Booked {int(v)} days in advance"
                if v > 0 else "Same-day booking"
            ),
            'paymentCollected': lambda v: (
                "Payment/deposit already collected" if v else "No deposit collected"
            ),
            'clientHasPaymentMethod': lambda v: (
                "Has payment method on file" if v else "No payment method on file"
            ),
            'isRecurring': lambda v: (
                "Recurring appointment (higher reliability)" if v
                else "One-time appointment"
            ),
            'hasIntakeForm': lambda v: (
                "Intake form already submitted" if v else "No intake form submitted"
            ),
            'clientLifecycleStage': lambda v: self._humanize_lifecycle(v),
            'slotHistoricalNoshowRate': lambda v: (
                f"Time slot has {int(v * 100)}% no-show history"
                if v > 0.1 else "Time slot has good attendance"
            ),
            'providerHistoricalNoshowRate': lambda v: (
                f"Provider's clients have {int(v * 100)}% no-show rate"
                if v > 0.1 else "Provider's clients rarely miss"
            ),
            'clientTotalAppointments': lambda v: (
                f"Client has attended {int(v)} appointments"
                if v > 0 else "New client, no history"
            ),
            'clientDaysSinceLastVisit': lambda v: (
                f"Last visit was {int(v)} days ago"
                if v > 0 else "Recent visit"
            ),
            'dayOfWeek': lambda v: self._humanize_day_of_week(v),
            'hourOfDay': lambda v: f"Appointment at {int(v):02d}:00",
            'serviceDurationMinutes': lambda v: f"{int(v)} minute service",
            'servicePriceCents': lambda v: f"${v / 100:.2f} service",
            'requiresPayment': lambda v: (
                "Payment required for service" if v else "Free service"
            ),
            'isGroupSession': lambda v: (
                "Group session (tends to have lower no-shows)" if v
                else "Individual appointment"
            ),
            'isFirstAppointmentOfDay': lambda v: (
                "First appointment of provider's day" if v
                else "Not first appointment"
            ),
            'isLastAppointmentOfDay': lambda v: (
                "Last appointment of provider's day" if v
                else "Not last appointment"
            ),
        }

        humanizer = explanations.get(feature_name)
        if humanizer:
            try:
                return humanizer(value)
            except Exception:
                pass

        # Fallback
        display_name = FEATURE_DISPLAY_NAMES.get(feature_name, feature_name)
        return f"{display_name}: {value}"

    def _humanize_lifecycle(self, stage) -> str:
        """Convert lifecycle stage to human-readable text."""
        stage_str = str(stage).lower()

        if 'new' in stage_str or stage_str == '0' or stage_str == '0.0':
            return "New client (less predictable)"
        elif 'active' in stage_str or stage_str == '1' or stage_str == '1.0':
            return "Active client (regular visitor)"
        elif 'inactive' in stage_str or stage_str == '2' or stage_str == '2.0':
            return "Inactive client (hasn't visited recently)"
        elif 'churn' in stage_str or stage_str == '3' or stage_str == '3.0':
            return "At-risk client (churning pattern)"
        else:
            return f"Client stage: {stage}"

    def _humanize_day_of_week(self, day: float) -> str:
        """Convert day number to human-readable."""
        days = {
            1: "Monday appointment",
            2: "Tuesday appointment",
            3: "Wednesday appointment",
            4: "Thursday appointment",
            5: "Friday appointment",
            6: "Saturday appointment",
            7: "Sunday appointment",
        }
        return days.get(int(day), f"Day {int(day)} appointment")

    def _generate_summary(
        self,
        factors: List[ExplanationFactor],
        probability: float,
        risk_level: str,
    ) -> str:
        """Generate a one-sentence summary of the prediction."""
        if not factors:
            return f"This appointment has a {risk_level} no-show risk."

        # Get the top increasing factor
        increasing = [f for f in factors if f.impact == "increases"]
        decreasing = [f for f in factors if f.impact == "decreases"]

        if risk_level == "high":
            if increasing:
                main_reason = increasing[0].explanation
                return f"High risk primarily because: {main_reason}"
            return "High no-show risk based on multiple factors."

        elif risk_level == "medium":
            if increasing and decreasing:
                return (
                    f"Mixed signals: {increasing[0].explanation}, "
                    f"but {decreasing[0].explanation}"
                )
            return "Moderate risk based on client and appointment patterns."

        else:  # low
            if decreasing:
                main_reason = decreasing[0].explanation
                return f"Low risk because: {main_reason}"
            return "Low no-show risk based on positive indicators."

    @property
    def is_shap_enabled(self) -> bool:
        """Check if SHAP explanations are available."""
        return self._use_shap and self._shap_explainer is not None


# Response schema for API
class ExplanationResponse:
    """API response format for explanations."""

    @staticmethod
    def from_explanation(explanation: PredictionExplanation) -> Dict[str, Any]:
        """Convert PredictionExplanation to API response dict."""
        return {
            "appointment_id": explanation.appointment_id,
            "probability": explanation.probability,
            "risk_level": explanation.risk_level,
            "summary": explanation.summary,
            "top_factors": [
                {
                    "feature": f.feature,
                    "display_name": f.display_name,
                    "impact": f.impact,
                    "magnitude": f.magnitude,
                    "explanation": f.explanation,
                    "feature_value": f.feature_value,
                }
                for f in explanation.top_factors
            ],
            "model_version": explanation.model_version,
            "explanation_version": explanation.explanation_version,
        }


# Singleton instance for app-wide use
_explainer_instance: Optional[PredictionExplainer] = None


def get_explainer() -> PredictionExplainer:
    """Get or create the singleton explainer instance."""
    global _explainer_instance
    if _explainer_instance is None:
        _explainer_instance = PredictionExplainer()
    return _explainer_instance


def set_explainer_model(model) -> bool:
    """
    Set the model for the singleton explainer.
    Call this after loading the LightGBM model.
    """
    explainer = get_explainer()
    return explainer.set_model(model)
