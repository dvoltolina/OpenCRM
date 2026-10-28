"""
Tests for sentiment analysis API.
Run with: pytest tests/ -v

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from datetime import datetime

# Import the app after mocking
import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))


class TestHealthEndpoints:
    """Tests for health check endpoints."""

    @pytest.fixture
    def client(self):
        """Create a test client with mocked dependencies."""
        from sentiment.providers import ProviderResult

        class FakeProvider:
            name = "fake"

            async def analyze(self, request):
                return ProviderResult(
                    sentiment_score=0.5,
                    confidence=0.9,
                    model_version="fake-model",
                    risk_indicators=[],
                    vip_indicators=[],
                    processing_time_ms=10,
                )

        with patch("sentiment.app.build_provider_stack", return_value=(FakeProvider(), FakeProvider())), \
             patch("sentiment.app.settings.require_authentication", False), \
             patch("sentiment.app.settings.require_jwt_auth", False):
            from sentiment.app import app

            with TestClient(app, base_url="https://testserver") as client:
                yield client

    def test_liveness(self, client):
        """Test liveness endpoint always returns alive."""
        response = client.get("/health/live")
        assert response.status_code == 200
        assert response.json()["status"] == "alive"

    def test_health_check(self, client):
        """Test health check returns expected fields."""
        response = client.get("/health")
        # May be degraded if Ollama not running
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "ollama_connected" in data
        assert "uptime_seconds" in data
        assert "total_analyses" in data


class TestAnalysisEndpoints:
    """Tests for analysis endpoints."""

    @pytest.fixture
    def sample_request(self):
        """Sample analysis request."""
        return {
            "text_id": "test_123",
            "business_id": "business_456",
            "client_id": "client_789",
            "text": "Thank you so much for the appointment! Your service was excellent.",
            "source": "smsReply",
            "deep_analysis": False,
        }

    @pytest.fixture
    def mock_client(self):
        """Create a test client with mocked dependencies."""
        from sentiment.providers import ProviderResult

        class FakeProvider:
            name = "fake"

            async def analyze(self, request):
                return ProviderResult(
                    sentiment_score=0.85,
                    confidence=0.92,
                    risk_indicators=[],
                    vip_indicators=[],
                    summary="Very positive feedback",
                    recommended_action=None,
                    model_version="fake-model",
                    processing_time_ms=250,
                )

        with patch("sentiment.app.build_provider_stack", return_value=(FakeProvider(), FakeProvider())), \
             patch("sentiment.app.settings.require_authentication", False), \
             patch("sentiment.app.settings.require_jwt_auth", False):
            from sentiment.app import app

            with TestClient(app, base_url="https://testserver") as client:
                yield client

    def test_analyze_sentiment_validation_missing_fields(self, mock_client):
        """Test request validation - missing required fields."""
        response = mock_client.post("/analyze/sentiment", json={})
        assert response.status_code == 422

    def test_analyze_sentiment_validation_empty_text(self, mock_client):
        """Test request validation - empty text."""
        response = mock_client.post(
            "/analyze/sentiment",
            json={
                "text_id": "test",
                "business_id": "biz",
                "client_id": "client",
                "text": "",
                "source": "smsReply",
            },
        )
        assert response.status_code == 422

    def test_analyze_sentiment_success(self, mock_client, sample_request):
        """Test successful sentiment analysis."""
        response = mock_client.post("/analyze/sentiment", json=sample_request)

        if response.status_code == 503:
            pytest.skip("Analyzer not initialized")

        assert response.status_code == 200
        data = response.json()

        assert data["client_id"] == "client_789"
        assert -1.0 <= data["sentiment_score"] <= 1.0
        assert 0.0 <= data["confidence"] <= 1.0
        assert isinstance(data["risk_indicators"], list)
        assert isinstance(data["vip_indicators"], list)

    def test_batch_analysis(self, mock_client, sample_request):
        """Test batch analysis endpoint."""
        request = {"texts": [sample_request, sample_request]}

        response = mock_client.post("/analyze/sentiment/batch", json=request)

        if response.status_code == 503:
            pytest.skip("Analyzer not initialized")

        assert response.status_code == 200
        data = response.json()

        assert data["total_processed"] == 2
        assert "processing_time_ms" in data

    def test_batch_analysis_exceeds_max(self, mock_client, sample_request):
        """Test batch analysis rejects oversized batches."""
        # Create request with too many texts (more than max_batch_size)
        request = {"texts": [sample_request] * 25}

        response = mock_client.post("/analyze/sentiment/batch", json=request)
        assert response.status_code == 400
        assert "exceeds maximum" in response.json()["detail"]


class TestSchemaValidation:
    """Tests for request/response schema validation."""

    def test_invalid_source(self):
        """Test that invalid source values are rejected."""
        from sentiment.schemas import AnalyzeTextRequest
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            AnalyzeTextRequest(
                text_id="test",
                business_id="biz",
                client_id="client",
                text="Hello",
                source="invalid_source",
            )

    def test_sentiment_score_bounds(self):
        """Test sentiment score validation bounds."""
        from sentiment.schemas import SentimentResultResponse
        from datetime import datetime, timedelta

        now = datetime.now()

        # Valid score
        result = SentimentResultResponse(
            id="test",
            business_id="biz",
            client_id="client",
            source="smsReply",
            analyzed_text="test",
            sentiment_score=0.5,
            confidence=0.8,
            model_version="test",
            analyzed_at=now,
            expires_at=now + timedelta(hours=1),
        )
        assert result.sentiment_score == 0.5

    def test_long_text_truncation(self):
        """Test that analyzed_text is truncated to 500 chars."""
        from sentiment.schemas import SentimentResultResponse
        from datetime import datetime, timedelta
        from pydantic import ValidationError

        now = datetime.now()
        long_text = "x" * 600

        # Should fail because analyzed_text exceeds max_length
        with pytest.raises(ValidationError):
            SentimentResultResponse(
                id="test",
                business_id="biz",
                client_id="client",
                source="smsReply",
                analyzed_text=long_text,
                sentiment_score=0.5,
                confidence=0.8,
                model_version="test",
                analyzed_at=now,
                expires_at=now + timedelta(hours=1),
            )
