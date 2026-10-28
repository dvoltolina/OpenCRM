"""
Tests for Pydantic schemas.
Run with: pytest tests/test_schemas.py -v

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
import pytest
from datetime import datetime, timedelta
from pydantic import ValidationError
import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from sentiment.schemas import (
    SentimentSource,
    IndicatorType,
    IndicatorSeverity,
    RiskIndicator,
    AnalyzeTextRequest,
    SentimentResultResponse,
    BatchAnalyzeRequest,
    BatchAnalyzeResponse,
    HealthStatus,
)


class TestSentimentSourceEnum:
    """Tests for SentimentSource enum."""

    def test_all_sources_have_camel_case_values(self):
        """Test all sources use camelCase values (matching Flutter)."""
        for source in SentimentSource:
            # camelCase starts with lowercase
            assert source.value[0].islower()
            # Should not contain underscores
            assert "_" not in source.value

    def test_expected_sources_exist(self):
        """Test all expected sources are defined."""
        expected = [
            "smsReply",
            "emailReply",
            "intakeFormText",
            "sessionNote",
            "cancellationReason",
            "rescheduleReason",
            "feedbackText",
            "staffNote",
        ]

        source_values = [s.value for s in SentimentSource]
        for expected_source in expected:
            assert expected_source in source_values


class TestIndicatorTypeEnum:
    """Tests for IndicatorType enum."""

    def test_indicator_types(self):
        """Test all indicator types are defined."""
        assert IndicatorType.RISK.value == "risk"
        assert IndicatorType.VIP.value == "vip"
        assert IndicatorType.NEUTRAL.value == "neutral"


class TestIndicatorSeverityEnum:
    """Tests for IndicatorSeverity enum."""

    def test_severity_levels(self):
        """Test all severity levels are defined."""
        assert IndicatorSeverity.CRITICAL.value == "critical"
        assert IndicatorSeverity.HIGH.value == "high"
        assert IndicatorSeverity.MEDIUM.value == "medium"
        assert IndicatorSeverity.LOW.value == "low"


class TestRiskIndicator:
    """Tests for RiskIndicator model."""

    def test_valid_risk_indicator(self):
        """Test creating a valid risk indicator."""
        indicator = RiskIndicator(
            id="ind_123",
            type=IndicatorType.RISK,
            severity=IndicatorSeverity.HIGH,
            category="churn_intent",
            description="Customer expressed intent to leave",
            confidence=0.85,
            source=SentimentSource.SMS_REPLY,
            trigger_text="I'm done with this",
            detected_at=datetime.now(),
            suggested_action="Contact immediately",
        )

        assert indicator.id == "ind_123"
        assert indicator.type == IndicatorType.RISK
        assert indicator.confidence == 0.85

    def test_confidence_bounds(self):
        """Test confidence must be between 0 and 1."""
        with pytest.raises(ValidationError):
            RiskIndicator(
                id="ind_123",
                type=IndicatorType.RISK,
                severity=IndicatorSeverity.HIGH,
                category="test",
                description="test",
                confidence=1.5,  # Invalid
                source=SentimentSource.SMS_REPLY,
                detected_at=datetime.now(),
            )


class TestAnalyzeTextRequest:
    """Tests for AnalyzeTextRequest model."""

    def test_valid_request(self):
        """Test creating a valid request."""
        request = AnalyzeTextRequest(
            text_id="test_123",
            business_id="biz_456",
            client_id="client_789",
            text="Hello, this is a test message",
            source=SentimentSource.SMS_REPLY,
        )

        assert request.text_id == "test_123"
        assert request.deep_analysis is False  # Default

    def test_empty_text_rejected(self):
        """Test that empty text is rejected."""
        with pytest.raises(ValidationError):
            AnalyzeTextRequest(
                text_id="test",
                business_id="biz",
                client_id="client",
                text="",
                source=SentimentSource.SMS_REPLY,
            )

    def test_text_max_length(self):
        """Test that overly long text is rejected."""
        long_text = "x" * 10001  # Exceeds max of 10000

        with pytest.raises(ValidationError):
            AnalyzeTextRequest(
                text_id="test",
                business_id="biz",
                client_id="client",
                text=long_text,
                source=SentimentSource.SMS_REPLY,
            )

    def test_invalid_source(self):
        """Test that invalid source is rejected."""
        with pytest.raises(ValidationError):
            AnalyzeTextRequest(
                text_id="test",
                business_id="biz",
                client_id="client",
                text="Hello",
                source="invalid_source",
            )


class TestSentimentResultResponse:
    """Tests for SentimentResultResponse model."""

    def test_valid_response(self):
        """Test creating a valid response."""
        now = datetime.now()
        response = SentimentResultResponse(
            id="sentiment_123",
            business_id="biz_456",
            client_id="client_789",
            source=SentimentSource.SMS_REPLY,
            analyzed_text="Hello, this is a test",
            sentiment_score=0.75,
            confidence=0.88,
            risk_indicators=[],
            vip_indicators=[],
            summary="Positive message",
            model_version="phi3:mini",
            analyzed_at=now,
            expires_at=now + timedelta(days=7),
        )

        assert response.id == "sentiment_123"
        assert response.sentiment_score == 0.75

    def test_sentiment_score_bounds(self):
        """Test sentiment score must be between -1 and 1."""
        now = datetime.now()

        # Test upper bound
        with pytest.raises(ValidationError):
            SentimentResultResponse(
                id="test",
                business_id="biz",
                client_id="client",
                source=SentimentSource.SMS_REPLY,
                analyzed_text="test",
                sentiment_score=1.5,  # Invalid
                confidence=0.5,
                model_version="test",
                analyzed_at=now,
                expires_at=now + timedelta(hours=1),
            )

        # Test lower bound
        with pytest.raises(ValidationError):
            SentimentResultResponse(
                id="test",
                business_id="biz",
                client_id="client",
                source=SentimentSource.SMS_REPLY,
                analyzed_text="test",
                sentiment_score=-1.5,  # Invalid
                confidence=0.5,
                model_version="test",
                analyzed_at=now,
                expires_at=now + timedelta(hours=1),
            )

    def test_analyzed_text_max_length(self):
        """Test analyzed_text max length enforcement."""
        now = datetime.now()
        long_text = "x" * 600  # Exceeds max of 500

        with pytest.raises(ValidationError):
            SentimentResultResponse(
                id="test",
                business_id="biz",
                client_id="client",
                source=SentimentSource.SMS_REPLY,
                analyzed_text=long_text,
                sentiment_score=0.5,
                confidence=0.5,
                model_version="test",
                analyzed_at=now,
                expires_at=now + timedelta(hours=1),
            )


class TestBatchAnalyzeRequest:
    """Tests for BatchAnalyzeRequest model."""

    def test_valid_batch_request(self):
        """Test creating a valid batch request."""
        texts = [
            AnalyzeTextRequest(
                text_id="1",
                business_id="biz",
                client_id="client",
                text="First message",
                source=SentimentSource.SMS_REPLY,
            ),
            AnalyzeTextRequest(
                text_id="2",
                business_id="biz",
                client_id="client",
                text="Second message",
                source=SentimentSource.EMAIL_REPLY,
            ),
        ]

        request = BatchAnalyzeRequest(texts=texts)
        assert len(request.texts) == 2


class TestHealthStatus:
    """Tests for HealthStatus model."""

    def test_valid_health_status(self):
        """Test creating a valid health status."""
        status = HealthStatus(
            status="healthy",
            ollama_connected=True,
            model_loaded="phi3:mini",
            models_available=["phi3:mini", "llama3.1:8b"],
            uptime_seconds=3600.0,
            total_analyses=100,
            avg_latency_ms=250.5,
            gpu_available=True,
            gpu_memory_used_mb=4096.0,
        )

        assert status.status == "healthy"
        assert status.ollama_connected is True
        assert len(status.models_available) == 2

    def test_health_status_without_gpu(self):
        """Test health status when GPU is not available."""
        status = HealthStatus(
            status="healthy",
            ollama_connected=True,
            model_loaded="phi3:mini",
            uptime_seconds=3600.0,
            total_analyses=100,
            avg_latency_ms=250.5,
            gpu_available=False,
        )

        assert status.gpu_available is False
        assert status.gpu_memory_used_mb is None
