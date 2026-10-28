"""
Pydantic schemas for prediction API.
MUST match Flutter models in lib/ai/models/ exactly.

Agent AI-3: Python Prediction Server
Schema Version: 1
"""
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


class RiskLevel(str, Enum):
    """Risk level for no-show predictions - matches Flutter RiskLevel enum."""
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    UNKNOWN = "unknown"


class ActionPriority(str, Enum):
    """Priority level for recommended actions - matches Flutter ActionPriority enum."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class PredictionFeaturesRequest(BaseModel):
    """
    Feature vector for no-show prediction.
    All fields required - Flutter extracts these before calling API.

    MUST match lib/ai/models/prediction_features.dart exactly.
    """
    # Metadata
    appointment_id: str = Field(..., description="Unique appointment identifier")
    business_id: str = Field(..., description="Business tenant ID")
    feature_schema_version: int = Field(default=1, description="Schema version for compatibility")

    # Client behavioral features
    client_historical_noshow_rate: float = Field(..., ge=0.0, le=1.0)
    client_historical_cancel_rate: float = Field(..., ge=0.0, le=1.0)
    client_total_appointments: int = Field(..., ge=0)
    client_days_since_last_visit: int = Field(..., ge=0)
    client_lifetime_value_cents: int = Field(..., ge=0)
    client_lifecycle_stage: str = Field(..., description="newClient, active, inactive, churned")
    client_has_payment_method: bool

    # Appointment context features
    booking_lead_days: int = Field(..., ge=0, le=365)
    day_of_week: int = Field(..., ge=1, le=7, description="1=Monday, 7=Sunday")
    hour_of_day: int = Field(..., ge=0, le=23)
    is_recurring: bool
    is_group_session: bool
    service_duration_minutes: int = Field(..., ge=1)
    service_price_cents: int = Field(..., ge=0)
    requires_payment: bool
    payment_collected: bool
    has_intake_form: bool

    # Provider features
    provider_historical_noshow_rate: float = Field(..., ge=0.0, le=1.0)
    provider_total_appointments: int = Field(..., ge=0)

    # Time slot features
    slot_historical_noshow_rate: float = Field(..., ge=0.0, le=1.0)
    is_first_appointment_of_day: bool
    is_last_appointment_of_day: bool

    @field_validator('client_lifecycle_stage')
    @classmethod
    def validate_lifecycle(cls, v: str) -> str:
        normalized = v.replace("Client", "client")
        valid_stages = ['newclient', 'newClient', 'active', 'inactive', 'churned']
        if normalized.lower() not in [stage.lower() for stage in valid_stages]:
            raise ValueError(f'lifecycle_stage must be one of {valid_stages}')
        return normalized.lower()

    def to_feature_vector(self) -> List[float]:
        """
        Convert to ordered feature vector for model input.
        ORDER MUST MATCH Flutter PredictionFeatures.toFeatureVector() EXACTLY.
        """
        return [
            # Client behavioral (7 features)
            self.client_historical_noshow_rate,
            self.client_historical_cancel_rate,
            float(self.client_total_appointments),
            float(self.client_days_since_last_visit),
            float(self.client_lifetime_value_cents),
            self._encode_lifecycle(self.client_lifecycle_stage),
            float(self.client_has_payment_method),

            # Appointment context (10 features)
            float(self.booking_lead_days),
            float(self.day_of_week),
            float(self.hour_of_day),
            float(self.is_recurring),
            float(self.is_group_session),
            float(self.service_duration_minutes),
            float(self.service_price_cents),
            float(self.requires_payment),
            float(self.payment_collected),
            float(self.has_intake_form),

            # Provider features (2 features)
            self.provider_historical_noshow_rate,
            float(self.provider_total_appointments),

            # Time slot features (3 features)
            self.slot_historical_noshow_rate,
            float(self.is_first_appointment_of_day),
            float(self.is_last_appointment_of_day),
        ]

    @staticmethod
    def _encode_lifecycle(stage: str) -> float:
        """
        Encode lifecycle stage as numeric value.
        MUST MATCH Flutter PredictionFeatures._encodeLifecycleStage() exactly.
        """
        encoding = {
            'newclient': 0.0,
            'active': 1.0,
            'inactive': 2.0,
            'churned': 3.0,
        }
        return encoding.get(stage.lower(), 0.0)

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
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
        }
    }


class FeatureImportance(BaseModel):
    """Which features contributed most to this prediction."""
    feature_name: str
    feature_display_name: str
    importance: float = Field(..., ge=0.0, le=1.0)
    feature_value: float
    impact: str = Field(..., description="increases_risk or decreases_risk")


class RecommendedAction(BaseModel):
    """Suggested action based on risk level."""
    action_id: str
    title: str
    description: str
    priority: ActionPriority
    automatable: bool
    icon_name: Optional[str] = None
    estimated_impact: Optional[float] = None


class NoshowPredictionResponse(BaseModel):
    """
    Prediction result returned to Flutter.
    MUST match lib/ai/models/noshow_prediction.dart NoshowPrediction class.
    """
    appointment_id: str
    probability: float = Field(..., ge=0.0, le=1.0)
    risk_level: RiskLevel
    confidence: float = Field(..., ge=0.0, le=1.0)
    recommended_actions: List[RecommendedAction]
    top_features: List[FeatureImportance]
    model_version: str
    predicted_at: datetime
    expires_at: datetime
    request_id: Optional[str] = None


class BatchPredictionRequest(BaseModel):
    """Request for multiple predictions at once."""
    appointments: List[PredictionFeaturesRequest]


class BatchPredictionResponse(BaseModel):
    """Response for batch predictions."""
    predictions: List[NoshowPredictionResponse]
    total_processed: int
    processing_time_ms: float


class ModelMetadata(BaseModel):
    """
    Information about the loaded model.
    MUST match lib/ai/models/model_metadata.dart ModelMetadata class.
    """
    model_id: str
    model_type: str
    version: str
    trained_at: datetime
    feature_schema_version: int
    metrics: Dict[str, float]
    feature_names: List[str]
    description: Optional[str] = None
    hyperparameters: Optional[Dict[str, Any]] = None


class HealthStatus(BaseModel):
    """Server health status."""
    status: str = Field(..., description="healthy, degraded, or unhealthy")
    model_loaded: bool
    model_metadata: Optional[ModelMetadata] = None
    uptime_seconds: float
    total_predictions: int
    avg_latency_ms: float
    last_prediction_at: Optional[datetime] = None
    error_message: Optional[str] = None


# Feature name constants - MUST match Flutter PredictionFeatures.featureNames
FEATURE_NAMES = [
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

FEATURE_DISPLAY_NAMES = {
    "clientHistoricalNoshowRate": "Client's Past No-Show Rate",
    "clientHistoricalCancelRate": "Client's Past Cancellation Rate",
    "clientTotalAppointments": "Client's Total Appointments",
    "clientDaysSinceLastVisit": "Days Since Last Visit",
    "clientLifetimeValueCents": "Client Lifetime Value",
    "clientLifecycleStage": "Client Lifecycle Stage",
    "clientHasPaymentMethod": "Has Payment Method on File",
    "bookingLeadDays": "Days Booked in Advance",
    "dayOfWeek": "Day of Week",
    "hourOfDay": "Hour of Day",
    "isRecurring": "Is Recurring Appointment",
    "isGroupSession": "Is Group Session",
    "serviceDurationMinutes": "Service Duration",
    "servicePriceCents": "Service Price",
    "requiresPayment": "Payment Required",
    "paymentCollected": "Payment Already Collected",
    "hasIntakeForm": "Intake Form Submitted",
    "providerHistoricalNoshowRate": "Provider's Client No-Show Rate",
    "providerTotalAppointments": "Provider's Total Appointments",
    "slotHistoricalNoshowRate": "Time Slot Historical No-Show Rate",
    "isFirstAppointmentOfDay": "First Appointment of Day",
    "isLastAppointmentOfDay": "Last Appointment of Day",
}
