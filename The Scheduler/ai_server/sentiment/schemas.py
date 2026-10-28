"""
Pydantic schemas for sentiment analysis API.
MUST match Flutter models in lib/ai/models/ exactly.

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


class SentimentSource(str, Enum):
    """Sources of analyzable text - must match Flutter enum."""
    SMS_REPLY = "smsReply"
    EMAIL_REPLY = "emailReply"
    INTAKE_FORM_TEXT = "intakeFormText"
    SESSION_NOTE = "sessionNote"
    CANCELLATION_REASON = "cancellationReason"
    RESCHEDULE_REASON = "rescheduleReason"
    FEEDBACK_TEXT = "feedbackText"
    STAFF_NOTE = "staffNote"


class IndicatorType(str, Enum):
    """Type of indicator detected - risk, VIP, or neutral."""
    RISK = "risk"
    VIP = "vip"
    NEUTRAL = "neutral"


class IndicatorSeverity(str, Enum):
    """Severity level for indicators."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class RiskIndicator(BaseModel):
    """A single risk or VIP indicator detected from text."""
    model_config = ConfigDict(populate_by_name=True, protected_namespaces=())

    id: str = Field(..., description="Unique identifier for this indicator")
    type: IndicatorType = Field(..., description="Type of indicator")
    severity: IndicatorSeverity = Field(..., description="Severity level")
    category: str = Field(..., description="Category of the indicator")
    description: str = Field(..., description="Human-readable description")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    source: SentimentSource = Field(..., description="Source of the analyzed text")
    source_document_id: Optional[str] = Field(
        None, description="ID of the source document"
    )
    trigger_text: Optional[str] = Field(
        None, description="Text that triggered this indicator"
    )
    detected_at: datetime = Field(..., description="When this indicator was detected")
    suggested_action: Optional[str] = Field(
        None, description="Suggested action to take"
    )


class AnalyzeTextRequest(BaseModel):
    """Request to analyze a single piece of text."""
    text_id: str = Field(..., description="Unique identifier for this text")
    business_id: str = Field(..., description="Business tenant ID")
    client_id: str = Field(..., description="Client this text belongs to")
    text: str = Field(..., min_length=1, max_length=10000, description="Text to analyze")
    source: SentimentSource = Field(..., description="Source of the text")
    source_document_id: Optional[str] = Field(
        None, description="ID of the source document"
    )
    deep_analysis: bool = Field(
        default=False,
        description="Use larger model for deeper analysis"
    )


class SentimentResultResponse(BaseModel):
    """Result of analyzing a single piece of text."""
    model_config = ConfigDict(protected_namespaces=())

    id: str = Field(..., description="Unique result ID")
    business_id: str = Field(..., description="Business tenant ID")
    client_id: str = Field(..., description="Client ID")
    source: SentimentSource = Field(..., description="Source of analyzed text")
    source_document_id: Optional[str] = Field(
        None, description="ID of the source document"
    )
    analyzed_text: str = Field(
        ..., max_length=500, description="Truncated text for storage"
    )
    sentiment_score: float = Field(
        ..., ge=-1.0, le=1.0, description="Sentiment score from -1 (negative) to 1 (positive)"
    )
    confidence: float = Field(
        ..., ge=0.0, le=1.0, description="Confidence in the analysis"
    )
    risk_indicators: List[RiskIndicator] = Field(
        default_factory=list, description="Detected risk indicators"
    )
    vip_indicators: List[RiskIndicator] = Field(
        default_factory=list, description="Detected VIP indicators"
    )
    summary: Optional[str] = Field(None, description="Summary of the sentiment")
    recommended_action: Optional[str] = Field(
        None, description="Recommended action to take"
    )
    model_version: str = Field(..., description="Model version used for analysis")
    analyzed_at: datetime = Field(..., description="When analysis was performed")
    expires_at: datetime = Field(..., description="When this result expires")
    processing_time_ms: Optional[int] = Field(
        None, description="Processing time in milliseconds"
    )


class BatchAnalyzeRequest(BaseModel):
    """Request to analyze multiple texts."""
    texts: List[AnalyzeTextRequest] = Field(
        ..., description="List of texts to analyze"
    )


class BatchAnalyzeResponse(BaseModel):
    """Response for batch analysis."""
    results: List[SentimentResultResponse] = Field(
        ..., description="Analysis results"
    )
    total_processed: int = Field(..., description="Total number processed")
    processing_time_ms: float = Field(..., description="Total processing time in ms")
    errors: List[Dict[str, str]] = Field(
        default_factory=list, description="Errors encountered during analysis"
    )


class HealthStatus(BaseModel):
    """Server health status."""
    model_config = ConfigDict(protected_namespaces=())

    status: str = Field(..., description="Overall status: healthy, degraded, unhealthy")
    ollama_connected: bool = Field(..., description="Whether Ollama is connected")
    model_loaded: str = Field(..., description="Currently loaded model")
    models_available: List[str] = Field(
        default_factory=list, description="Available models"
    )
    uptime_seconds: float = Field(..., description="Server uptime in seconds")
    total_analyses: int = Field(..., description="Total analyses performed")
    avg_latency_ms: float = Field(..., description="Average latency in milliseconds")
    gpu_available: bool = Field(..., description="Whether GPU is available")
    gpu_memory_used_mb: Optional[float] = Field(
        None, description="GPU memory used in MB"
    )
    provider: Optional[str] = Field(
        None, description="Active sentiment provider"
    )
    using_fallback: Optional[bool] = Field(
        default=False, description="Whether the fallback provider is active"
    )
