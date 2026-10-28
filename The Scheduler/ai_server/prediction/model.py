"""
Model loading and inference for no-show prediction.
Supports LightGBM models with hot-reload capability.

Agent AI-3: Python Prediction Server
"""
import json
import logging
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, List

import numpy as np

try:
    import lightgbm as lgb
    LIGHTGBM_AVAILABLE = True
except ImportError:
    LIGHTGBM_AVAILABLE = False
    lgb = None

from .schemas import (
    PredictionFeaturesRequest,
    NoshowPredictionResponse,
    FeatureImportance,
    RecommendedAction,
    ModelMetadata,
    RiskLevel,
    ActionPriority,
    FEATURE_NAMES,
    FEATURE_DISPLAY_NAMES,
)

logger = logging.getLogger(__name__)


class ModelManager:
    """
    Manages model loading, versioning, and inference.

    Supports:
    - LightGBM binary models (.lgb)
    - Model metadata JSON files
    - Hot-reload without restart
    - Feature importance extraction
    - Mock mode for development/testing
    """

    def __init__(self, models_dir: str = "models"):
        self.models_dir = Path(models_dir)
        self.model: Optional[object] = None
        self.metadata: Optional[ModelMetadata] = None
        self._loaded_at: Optional[datetime] = None
        self._prediction_count: int = 0
        self._total_latency_ms: float = 0.0
        self._last_prediction_at: Optional[datetime] = None
        self._use_mock: bool = False

    def load_model(self, model_name: str = "noshow_model") -> bool:
        """
        Load a model from the models directory.

        Args:
            model_name: Base name of model files (without extension)

        Returns:
            True if loaded successfully (or mock mode), False otherwise
        """
        model_path = self.models_dir / f"{model_name}.lgb"
        metadata_path = self.models_dir / f"{model_name}_metadata.json"

        try:
            # Check if model file exists
            if not model_path.exists():
                logger.warning(f"Model file not found: {model_path}")
                logger.info("Starting in mock mode - will generate synthetic predictions")
                self._use_mock = True
                self._create_mock_metadata(model_name)
                self._loaded_at = datetime.now()
                return True

            # Check if LightGBM is available
            if not LIGHTGBM_AVAILABLE:
                logger.warning("LightGBM not installed - starting in mock mode")
                self._use_mock = True
                self._create_mock_metadata(model_name)
                self._loaded_at = datetime.now()
                return True

            # Load LightGBM model
            self.model = lgb.Booster(model_file=str(model_path))
            self._use_mock = False
            logger.info(f"Loaded LightGBM model from {model_path}")

            # Load metadata if exists
            if metadata_path.exists():
                with open(metadata_path, 'r') as f:
                    meta_dict = json.load(f)
                    self.metadata = ModelMetadata(
                        model_id=meta_dict.get('model_id', model_name),
                        model_type=meta_dict.get('model_type', 'lightgbm'),
                        version=meta_dict.get('version', '1.0.0'),
                        trained_at=datetime.fromisoformat(
                            meta_dict.get('trained_at', datetime.now().isoformat())
                        ),
                        feature_schema_version=meta_dict.get('feature_schema_version', 1),
                        metrics=meta_dict.get('metrics', {}),
                        feature_names=meta_dict.get('feature_names', FEATURE_NAMES),
                        description=meta_dict.get('description'),
                        hyperparameters=meta_dict.get('hyperparameters'),
                    )
            else:
                self._create_default_metadata(model_name)

            self._loaded_at = datetime.now()
            return True

        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            # Fall back to mock mode
            self._use_mock = True
            self._create_mock_metadata(model_name)
            self._loaded_at = datetime.now()
            return True

    def _create_mock_metadata(self, model_name: str) -> None:
        """Create metadata for mock mode."""
        self.metadata = ModelMetadata(
            model_id=f"{model_name}_mock",
            model_type='mock',
            version='0.0.1-mock',
            trained_at=datetime.now(),
            feature_schema_version=1,
            metrics={'note': 'Mock model - predictions are synthetic'},
            feature_names=FEATURE_NAMES,
            description="Mock model for development/testing",
        )

    def _create_default_metadata(self, model_name: str) -> None:
        """Create default metadata when no metadata file exists."""
        self.metadata = ModelMetadata(
            model_id=model_name,
            model_type='lightgbm',
            version='1.0.0',
            trained_at=datetime.now(),
            feature_schema_version=1,
            metrics={},
            feature_names=FEATURE_NAMES,
        )

    def reload_model(self, model_name: str = "noshow_model") -> bool:
        """Hot-reload model without restart."""
        logger.info(f"Hot-reloading model: {model_name}")
        return self.load_model(model_name)

    def predict(
        self,
        features: PredictionFeaturesRequest,
        high_risk_threshold: float = 0.7,
        medium_risk_threshold: float = 0.4,
        cache_ttl_minutes: int = 15,
    ) -> NoshowPredictionResponse:
        """
        Generate no-show prediction for an appointment.

        Args:
            features: Extracted features for the appointment
            high_risk_threshold: Probability threshold for high risk
            medium_risk_threshold: Probability threshold for medium risk
            cache_ttl_minutes: How long prediction is valid

        Returns:
            NoshowPredictionResponse with probability and recommendations
        """
        start_time = time.time()

        # Convert to feature vector
        feature_vector = np.array([features.to_feature_vector()])

        # Get prediction (real or mock)
        if self._use_mock:
            probability = self._mock_predict(features)
        else:
            probability = float(self.model.predict(feature_vector)[0])

        # Clamp probability to valid range
        probability = max(0.0, min(1.0, probability))

        # Determine risk level
        if probability >= high_risk_threshold:
            risk_level = RiskLevel.HIGH
        elif probability >= medium_risk_threshold:
            risk_level = RiskLevel.MEDIUM
        else:
            risk_level = RiskLevel.LOW

        # Calculate confidence (based on model's certainty)
        confidence = abs(probability - 0.5) * 2  # Scale to 0-1

        # Get feature importances
        top_features = self._get_feature_importances(
            feature_vector[0],
            probability,
            num_features=5
        )

        # Generate recommended actions
        recommended_actions = self._generate_recommendations(
            risk_level,
            probability,
            features
        )

        # Calculate timing
        latency_ms = (time.time() - start_time) * 1000
        self._prediction_count += 1
        self._total_latency_ms += latency_ms
        self._last_prediction_at = datetime.now()

        now = datetime.now()

        return NoshowPredictionResponse(
            appointment_id=features.appointment_id,
            probability=probability,
            risk_level=risk_level,
            confidence=confidence,
            recommended_actions=recommended_actions,
            top_features=top_features,
            model_version=self.metadata.version if self.metadata else "unknown",
            predicted_at=now,
            expires_at=now + timedelta(minutes=cache_ttl_minutes),
        )

    def _mock_predict(self, features: PredictionFeaturesRequest) -> float:
        """
        Generate synthetic prediction based on features.
        Used when real model is not available.
        """
        # Base probability
        probability = 0.1

        # Increase based on historical no-show rate (strongest signal)
        probability += features.client_historical_noshow_rate * 0.4

        # Increase based on cancellation history
        probability += features.client_historical_cancel_rate * 0.2

        # Decrease for payment collected
        if features.payment_collected:
            probability -= 0.15

        # Decrease for payment method on file
        if features.client_has_payment_method:
            probability -= 0.1

        # Increase for long booking lead time
        if features.booking_lead_days > 14:
            probability += 0.1
        elif features.booking_lead_days > 7:
            probability += 0.05

        # Decrease for recurring appointments
        if features.is_recurring:
            probability -= 0.1

        # Decrease for intake form submitted
        if features.has_intake_form:
            probability -= 0.05

        # New clients have higher uncertainty
        if features.client_lifecycle_stage.lower() == 'newclient':
            probability += 0.05
        elif features.client_lifecycle_stage.lower() == 'churned':
            probability += 0.15

        # Slot historical rate influence
        probability += features.slot_historical_noshow_rate * 0.1

        return max(0.0, min(1.0, probability))

    def predict_batch(
        self,
        features_list: List[PredictionFeaturesRequest],
        **kwargs
    ) -> List[NoshowPredictionResponse]:
        """Predict for multiple appointments efficiently."""
        return [self.predict(f, **kwargs) for f in features_list]

    def _get_feature_importances(
        self,
        feature_vector: np.ndarray,
        probability: float,
        num_features: int = 5,
    ) -> List[FeatureImportance]:
        """
        Extract which features contributed most to this prediction.
        """
        # Get model's global feature importances if available
        if not self._use_mock and self.model is not None:
            try:
                importances = self.model.feature_importance(importance_type='gain')
                if importances.sum() > 0:
                    importances = importances / importances.sum()
            except Exception:
                importances = self._get_mock_importances()
        else:
            importances = self._get_mock_importances()

        # Build feature importance list
        results = []
        for i, (name, importance) in enumerate(zip(FEATURE_NAMES, importances)):
            value = feature_vector[i] if i < len(feature_vector) else 0.0

            # Determine if this feature increases or decreases risk
            impact = self._determine_impact(name, value, probability)

            results.append(FeatureImportance(
                feature_name=name,
                feature_display_name=FEATURE_DISPLAY_NAMES.get(name, name),
                importance=float(importance),
                feature_value=float(value),
                impact=impact,
            ))

        # Sort by importance and return top N
        results.sort(key=lambda x: x.importance, reverse=True)
        return results[:num_features]

    def _get_mock_importances(self) -> np.ndarray:
        """Generate mock feature importances based on domain knowledge."""
        # Realistic importance weights based on no-show research
        weights = {
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
            'requiresPayment': 0.01,
            'dayOfWeek': 0.01,
            'hourOfDay': 0.01,
        }

        importances = []
        for name in FEATURE_NAMES:
            importances.append(weights.get(name, 0.0))

        return np.array(importances)

    def _determine_impact(self, name: str, value: float, probability: float) -> str:
        """Determine if a feature value increases or decreases risk."""
        # Features that decrease risk when true/high
        decreases_risk_when_high = [
            'paymentCollected', 'clientHasPaymentMethod', 'hasIntakeForm',
            'isRecurring', 'clientTotalAppointments', 'providerTotalAppointments'
        ]

        # Features that increase risk when high
        increases_risk_when_high = [
            'clientHistoricalNoshowRate', 'clientHistoricalCancelRate',
            'bookingLeadDays', 'slotHistoricalNoshowRate',
            'providerHistoricalNoshowRate', 'clientDaysSinceLastVisit'
        ]

        if name in decreases_risk_when_high:
            return 'decreases_risk' if value > 0.5 else 'increases_risk'
        elif name in increases_risk_when_high:
            return 'increases_risk' if value > 0.2 else 'decreases_risk'
        else:
            return 'increases_risk' if probability > 0.5 else 'decreases_risk'

    def _generate_recommendations(
        self,
        risk_level: RiskLevel,
        probability: float,
        features: PredictionFeaturesRequest,
    ) -> List[RecommendedAction]:
        """Generate actionable recommendations based on risk factors."""
        actions = []

        if risk_level == RiskLevel.HIGH:
            # Always recommend confirmation for high risk
            actions.append(RecommendedAction(
                action_id="send_priority_confirmation",
                title="Send Priority Confirmation",
                description="Send an urgent confirmation SMS/call to the client",
                priority=ActionPriority.CRITICAL,
                automatable=True,
                icon_name="notifications_active",
                estimated_impact=0.15,
            ))

            # Check if payment not collected
            if features.requires_payment and not features.payment_collected:
                actions.append(RecommendedAction(
                    action_id="require_deposit",
                    title="Require Deposit",
                    description="Request payment/deposit before appointment",
                    priority=ActionPriority.HIGH,
                    automatable=True,
                    icon_name="payment",
                    estimated_impact=0.25,
                ))

            # Add to overbook candidates
            actions.append(RecommendedAction(
                action_id="add_overbook_candidate",
                title="Enable Overbooking",
                description="Add this slot as an overbooking candidate",
                priority=ActionPriority.MEDIUM,
                automatable=True,
                icon_name="event_repeat",
                estimated_impact=0.0,
            ))

            # Manual follow-up
            actions.append(RecommendedAction(
                action_id="schedule_confirmation_call",
                title="Schedule Confirmation Call",
                description="Have staff personally confirm with client",
                priority=ActionPriority.HIGH,
                automatable=False,
                icon_name="phone",
                estimated_impact=0.20,
            ))

        elif risk_level == RiskLevel.MEDIUM:
            actions.append(RecommendedAction(
                action_id="send_extra_reminder",
                title="Send Additional Reminder",
                description="Send an extra reminder 24 hours before",
                priority=ActionPriority.MEDIUM,
                automatable=True,
                icon_name="notifications",
                estimated_impact=0.10,
            ))

            if not features.payment_collected and features.requires_payment:
                actions.append(RecommendedAction(
                    action_id="suggest_deposit",
                    title="Suggest Deposit",
                    description="Encourage client to pay in advance",
                    priority=ActionPriority.LOW,
                    automatable=True,
                    icon_name="payment",
                    estimated_impact=0.15,
                ))

            actions.append(RecommendedAction(
                action_id="request_confirmation",
                title="Request Confirmation",
                description="Ask client to confirm attendance",
                priority=ActionPriority.MEDIUM,
                automatable=True,
                icon_name="check_circle",
                estimated_impact=0.10,
            ))

        else:  # LOW risk
            actions.append(RecommendedAction(
                action_id="standard_reminder",
                title="Standard Reminder",
                description="Send standard appointment reminder",
                priority=ActionPriority.LOW,
                automatable=True,
                icon_name="notifications",
                estimated_impact=0.05,
            ))

        return actions

    @property
    def is_loaded(self) -> bool:
        """Check if model is loaded (real or mock)."""
        return self.metadata is not None

    @property
    def is_mock(self) -> bool:
        """Check if using mock predictions."""
        return self._use_mock

    @property
    def stats(self) -> dict:
        """Get prediction statistics."""
        return {
            "prediction_count": self._prediction_count,
            "avg_latency_ms": (
                self._total_latency_ms / self._prediction_count
                if self._prediction_count > 0 else 0
            ),
            "loaded_at": self._loaded_at.isoformat() if self._loaded_at else None,
            "last_prediction_at": (
                self._last_prediction_at.isoformat()
                if self._last_prediction_at else None
            ),
            "is_mock": self._use_mock,
        }
