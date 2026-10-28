"""
Sentiment analysis orchestrator with pluggable providers.

Agent AI-6: Python Sentiment Service (Ollama LLM -> multi-provider)
"""
import logging
import uuid
from datetime import datetime, timedelta
from typing import List, Optional, Tuple

from .providers import ProviderResult
from .risk_keywords import RiskKeywordMatcher
from .schemas import AnalyzeTextRequest, RiskIndicator, SentimentResultResponse

logger = logging.getLogger(__name__)


class SentimentAnalyzer:
    """
    Analyzes text for sentiment using a primary provider with VADER fallback.
    """

    def __init__(
        self,
        provider: object,
        fallback_provider: object,
        risk_matcher: RiskKeywordMatcher,
        result_ttl_hours: int = 168,  # 7 days
    ):
        self.provider = provider
        self.fallback_provider = fallback_provider
        self.risk_matcher = risk_matcher
        self.result_ttl_hours = result_ttl_hours
        self._analysis_count = 0

    async def analyze(self, request: AnalyzeTextRequest) -> SentimentResultResponse:
        """
        Analyze a single text for sentiment.
        """
        provider_used = getattr(self.provider, "name", "unknown")
        provider_result: ProviderResult

        try:
            provider_result = await self.provider.analyze(request)
            fallback_used = False
        except Exception as exc:
            logger.warning(
                "Primary provider %s failed for text_id=%s. Falling back. Error=%s",
                provider_used,
                request.text_id,
                type(exc).__name__,
            )
            provider_result = await self.fallback_provider.analyze(request)
            provider_used = getattr(self.fallback_provider, "name", "fallback")
            fallback_used = True

        self._analysis_count += 1

        sentiment_score = max(-1.0, min(1.0, provider_result.sentiment_score))
        confidence = min(1.0, max(0.0, provider_result.confidence))

        risk_indicators, vip_indicators = self._merge_indicators(
            provider_result.risk_indicators,
            provider_result.vip_indicators,
            request,
        )

        now = datetime.now()
        result_id_prefix = "sentiment_fallback_" if fallback_used else "sentiment_"

        return SentimentResultResponse(
            id=f"{result_id_prefix}{request.text_id}_{uuid.uuid4().hex[:8]}",
            business_id=request.business_id,
            client_id=request.client_id,
            source=request.source,
            source_document_id=request.source_document_id,
            analyzed_text=request.text[:500],
            sentiment_score=sentiment_score,
            confidence=confidence,
            risk_indicators=risk_indicators,
            vip_indicators=vip_indicators,
            summary=provider_result.summary,
            recommended_action=provider_result.recommended_action,
            model_version=f"{provider_used}:{provider_result.model_version}",
            analyzed_at=now,
            expires_at=now + timedelta(hours=self.result_ttl_hours),
            processing_time_ms=provider_result.processing_time_ms,
        )

    async def analyze_batch(
        self,
        requests: List[AnalyzeTextRequest],
        max_batch_size: int = 5,
    ) -> List[SentimentResultResponse]:
        """
        Analyze multiple texts.

        For small batches, processes in sequence.
        For larger batches, splits into smaller chunks.
        """
        results: List[SentimentResultResponse] = []

        if len(requests) <= max_batch_size:
            for request in requests:
                try:
                    result = await self.analyze(request)
                    results.append(result)
                except Exception as exc:
                    logger.error("Failed to analyze text %s: %s", request.text_id, exc)
                    results.append(self._create_error_result(request, str(exc)))
        else:
            for i in range(0, len(requests), max_batch_size):
                chunk = requests[i : i + max_batch_size]
                results.extend(await self._analyze_batch_chunk(chunk))

        return results

    async def _analyze_batch_chunk(
        self,
        requests: List[AnalyzeTextRequest],
    ) -> List[SentimentResultResponse]:
        """Analyze a chunk of texts using the same provider pipeline."""
        results: List[SentimentResultResponse] = []
        for request in requests:
            try:
                results.append(await self.analyze(request))
            except Exception as exc:
                logger.error("Batch analysis failed for %s: %s", request.text_id, exc)
                results.append(self._create_error_result(request, str(exc)))
        return results

    def _merge_indicators(
        self,
        provider_risk: List[RiskIndicator],
        provider_vip: List[RiskIndicator],
        request: AnalyzeTextRequest,
    ) -> Tuple[List[RiskIndicator], List[RiskIndicator]]:
        """Merge provider indicators with keyword-based detections."""
        keyword_risk, keyword_vip = self.risk_matcher.match(
            text=request.text,
            source=request.source,
            source_document_id=request.source_document_id,
        )

        risk_combined = (provider_risk or []) + keyword_risk
        vip_combined = (provider_vip or []) + keyword_vip

        return risk_combined, vip_combined

    def _create_error_result(
        self,
        request: AnalyzeTextRequest,
        error: str,
    ) -> SentimentResultResponse:
        """Create a result for failed analysis."""
        now = datetime.now()
        return SentimentResultResponse(
            id=f"sentiment_error_{request.text_id}",
            business_id=request.business_id,
            client_id=request.client_id,
            source=request.source,
            source_document_id=request.source_document_id,
            analyzed_text=request.text[:500],
            sentiment_score=0.0,
            confidence=0.0,
            risk_indicators=[],
            vip_indicators=[],
            summary=f"Analysis failed: {error}",
            recommended_action=None,
            model_version="error",
            analyzed_at=now,
            expires_at=now + timedelta(hours=1),
            processing_time_ms=0,
        )

    @property
    def analysis_count(self) -> int:
        """Get the total number of analyses performed."""
        return self._analysis_count
