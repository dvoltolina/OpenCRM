"""
Tests for sentiment analyzer logic with provider abstraction.
"""
import pytest
import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from sentiment.analyzer import SentimentAnalyzer
from sentiment.providers import ProviderResult
from sentiment.risk_keywords import RiskKeywordMatcher
from sentiment.schemas import AnalyzeTextRequest, SentimentSource


class FakeProvider:
    def __init__(self, name="primary", score=0.5, confidence=0.9, fail=False):
        self.name = name
        self.score = score
        self.confidence = confidence
        self.fail = fail

    async def analyze(self, request):
        if self.fail:
            raise RuntimeError("provider failure")
        return ProviderResult(
            sentiment_score=self.score,
            confidence=self.confidence,
            model_version=self.name,
            risk_indicators=[],
            vip_indicators=[],
            processing_time_ms=10,
        )


@pytest.fixture
def sample_request():
    return AnalyzeTextRequest(
        text_id="test_123",
        business_id="business_456",
        client_id="client_789",
        text="Thank you so much!",
        source=SentimentSource.SMS_REPLY,
    )


@pytest.mark.asyncio
async def test_analyze_uses_primary_provider(sample_request):
    analyzer = SentimentAnalyzer(
        provider=FakeProvider(score=0.8, confidence=0.95),
        fallback_provider=FakeProvider(name="fallback", score=0.1),
        risk_matcher=RiskKeywordMatcher(),
        result_ttl_hours=1,
    )

    result = await analyzer.analyze(sample_request)

    assert result.sentiment_score == 0.8
    # Keyword matcher should add gratitude VIP indicator
    assert len(result.vip_indicators) >= 1
    assert result.confidence <= 1.0


@pytest.mark.asyncio
async def test_fallback_provider_used_on_failure(sample_request):
    analyzer = SentimentAnalyzer(
        provider=FakeProvider(fail=True),
        fallback_provider=FakeProvider(name="fallback", score=-0.2, confidence=0.6),
        risk_matcher=RiskKeywordMatcher(),
        result_ttl_hours=1,
    )

    result = await analyzer.analyze(sample_request)

    assert result.sentiment_score == -0.2
    assert result.id.startswith("sentiment_fallback_")


@pytest.mark.asyncio
async def test_confidence_is_clamped(sample_request):
    analyzer = SentimentAnalyzer(
        provider=FakeProvider(score=0.4, confidence=2.0),
        fallback_provider=FakeProvider(name="fallback", score=0.0),
        risk_matcher=RiskKeywordMatcher(),
        result_ttl_hours=1,
    )

    result = await analyzer.analyze(sample_request)

    assert 0.0 <= result.confidence <= 1.0
