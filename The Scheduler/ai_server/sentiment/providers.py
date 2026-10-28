"""
Provider abstraction for sentiment analysis.

Supports hosted providers (Google NL, OpenAI), local Ollama, and VADER/TextBlob
fallback. All providers avoid logging raw text and enforce HTTPS for outbound
requests unless explicitly allowed for localhost during development.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import time
from datetime import datetime
from dataclasses import dataclass, field
from typing import List, Optional, Tuple
from urllib.parse import urlparse

from .config import get_settings
from .ollama_client import OllamaClient
from .schemas import AnalyzeTextRequest, RiskIndicator, IndicatorSeverity, IndicatorType
from .prompts import SENTIMENT_SYSTEM_PROMPT, build_analysis_prompt

logger = logging.getLogger(__name__)


class ProviderUnavailable(Exception):
    """Raised when a provider cannot be used (missing deps/keys/https, etc.)."""


@dataclass
class ProviderResult:
    """Normalized sentiment result returned by providers."""

    sentiment_score: float
    confidence: float
    summary: Optional[str] = None
    recommended_action: Optional[str] = None
    risk_indicators: List[RiskIndicator] = field(default_factory=list)
    vip_indicators: List[RiskIndicator] = field(default_factory=list)
    model_version: str = "unknown"
    processing_time_ms: int = 0


def _enforce_https(url: str, allow_local_http: bool, require_https: bool) -> None:
    """Ensure outbound URL is HTTPS unless explicitly allowed for localhost."""
    if not require_https:
        return

    parsed = urlparse(url)
    if parsed.scheme == "https":
        return

    if allow_local_http and parsed.hostname in {"localhost", "127.0.0.1"}:
        return

    raise ProviderUnavailable(f"Insecure provider endpoint blocked: {url}")


class GoogleLanguageProvider:
    """Google Cloud Natural Language sentiment provider."""

    name = "google"

    def __init__(
        self,
        endpoint: str,
        model_version: str,
        require_https: bool,
        allow_local_http: bool,
    ):
        _enforce_https(endpoint, allow_local_http, require_https)

        try:
            from google.cloud import language_v1
        except Exception as exc:  # pragma: no cover - import guarded in tests
            raise ProviderUnavailable("google-cloud-language package not installed") from exc

        # Ensure credentials exist
        credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if not credentials_path or not os.path.exists(credentials_path):
            raise ProviderUnavailable("GOOGLE_APPLICATION_CREDENTIALS is not set or file is missing")

        self._language = language_v1
        self._client = language_v1.LanguageServiceClient(
            client_options={"api_endpoint": endpoint}
        )
        self._model_version = model_version

    async def analyze(self, request: AnalyzeTextRequest) -> ProviderResult:
        return await asyncio.to_thread(self._analyze_sync, request)

    def _analyze_sync(self, request: AnalyzeTextRequest) -> ProviderResult:
        start = time.time()
        document = self._language.Document(
            content=request.text,
            type_=self._language.Document.Type.PLAIN_TEXT,
        )
        response = self._client.analyze_sentiment(
            document=document,
            encoding_type=self._language.EncodingType.UTF8,
        )
        sentiment = response.document_sentiment
        score = float(sentiment.score or 0.0)
        magnitude = float(sentiment.magnitude or 0.0)

        # Confidence derived from score and magnitude
        confidence = min(1.0, max(0.0, abs(score) + min(magnitude / 2, 0.5)))

        processing_ms = int((time.time() - start) * 1000)
        language = getattr(response, "language", None) or "und"

        return ProviderResult(
            sentiment_score=max(-1.0, min(1.0, score)),
            confidence=confidence,
            summary=None,
            recommended_action=None,
            model_version=f"{self._model_version}:{language}",
            processing_time_ms=processing_ms,
        )


class OpenAIProvider:
    """OpenAI-hosted sentiment provider using JSON-mode Chat Completions."""

    name = "openai"

    def __init__(
        self,
        api_key: Optional[str],
        base_url: str,
        model: str,
        timeout: float,
        require_https: bool,
        allow_local_http: bool,
    ):
        if not api_key:
            raise ProviderUnavailable("OPENAI_API_KEY is not configured")

        _enforce_https(base_url, allow_local_http, require_https)

        try:
            from openai import OpenAI
        except Exception as exc:  # pragma: no cover - import guarded in tests
            raise ProviderUnavailable("openai package not installed") from exc

        self._client = OpenAI(api_key=api_key, base_url=base_url, timeout=timeout)
        self._model = model

    async def analyze(self, request: AnalyzeTextRequest) -> ProviderResult:
        return await asyncio.to_thread(self._analyze_sync, request)

    def _analyze_sync(self, request: AnalyzeTextRequest) -> ProviderResult:
        start = time.time()
        completion = self._client.chat.completions.create(
            model=self._model,
            response_format={"type": "json_object"},
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a sentiment analysis service. "
                        "Return JSON with fields: sentiment_score (-1..1), confidence (0..1), "
                        "summary, recommended_action, risk_indicators[], vip_indicators[]. "
                        "risk/vip indicator items include category, description, severity (critical|high|medium|low). "
                        "Keep output compact."
                    ),
                },
                {
                    "role": "user",
                    "content": request.text,
                },
            ],
        )

        message = completion.choices[0].message.content or "{}"
        try:
            payload = json.loads(message)
        except json.JSONDecodeError:
            payload = {}

        score = float(payload.get("sentiment_score", 0.0))
        confidence = float(payload.get("confidence", abs(score)))

        risk = self._parse_indicators(payload.get("risk_indicators", []), IndicatorType.RISK, request)
        vip = self._parse_indicators(payload.get("vip_indicators", []), IndicatorType.VIP, request)

        processing_ms = int((time.time() - start) * 1000)

        return ProviderResult(
            sentiment_score=max(-1.0, min(1.0, score)),
            confidence=min(1.0, max(0.0, confidence)),
            summary=payload.get("summary"),
            recommended_action=payload.get("recommended_action"),
            risk_indicators=risk,
            vip_indicators=vip,
            model_version=completion.model or self._model,
            processing_time_ms=processing_ms,
        )

    def _parse_indicators(
        self,
        items: List[dict],
        indicator_type: IndicatorType,
        request: AnalyzeTextRequest,
    ) -> List[RiskIndicator]:
        parsed: List[RiskIndicator] = []
        for raw in items or []:
            try:
                severity = raw.get("severity", "medium").lower()
                if severity not in {"critical", "high", "medium", "low"}:
                    severity = "medium"
                parsed.append(
                    RiskIndicator(
                        id=f"ind_{indicator_type.value}_{len(parsed)+1}",
                        type=indicator_type,
                        severity=IndicatorSeverity(severity),
                        category=raw.get("category", "unknown"),
                        description=raw.get("description", ""),
                        confidence=min(1.0, max(0.0, float(raw.get("confidence", 0.7)))),
                        source=request.source,
                        source_document_id=request.source_document_id,
                        trigger_text=raw.get("trigger_text"),
                        detected_at=datetime.utcnow(),
                        suggested_action=raw.get("suggested_action"),
                    )
                )
            except Exception:
                continue
        return parsed


class OllamaProvider:
    """Local Ollama provider (used in legacy flow)."""

    name = "ollama"

    def __init__(
        self,
        ollama_url: str,
        default_model: str,
        deep_analysis_model: str,
        timeout: float,
        require_https: bool,
        allow_local_http: bool,
    ):
        _enforce_https(ollama_url, allow_local_http, require_https)
        self._client = OllamaClient(
            base_url=ollama_url,
            timeout=timeout,
            default_model=default_model,
            deep_analysis_model=deep_analysis_model,
        )

    async def analyze(self, request: AnalyzeTextRequest) -> ProviderResult:
        analysis_prompt = build_analysis_prompt(
            text=request.text,
            source=request.source.value,
            deep=request.deep_analysis,
        )
        result = await self._client.analyze_sentiment(
            text=request.text,
            source=request.source.value,
            system_prompt=SENTIMENT_SYSTEM_PROMPT,
            analysis_prompt=analysis_prompt,
            deep=request.deep_analysis,
        )

        meta = result.get("_meta", {})
        return ProviderResult(
            sentiment_score=max(-1.0, min(1.0, float(result.get("sentiment_score", 0.0)))),
            confidence=min(1.0, max(0.0, float(result.get("confidence", 0.5)))),
            summary=result.get("summary"),
            recommended_action=result.get("recommended_action"),
            risk_indicators=result.get("risk_indicators", []),
            vip_indicators=result.get("vip_indicators", []),
            model_version=meta.get("model", "ollama"),
            processing_time_ms=int(meta.get("processing_time_ms", 0)),
        )


class VaderProvider:
    """Local lexicon-based fallback (VADER/TextBlob)."""

    name = "vader"

    def __init__(self, enable_textblob: bool):
        try:
            from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        except Exception as exc:  # pragma: no cover - import guarded in tests
            raise ProviderUnavailable("vaderSentiment package not installed") from exc

        self._analyzer = SentimentIntensityAnalyzer()
        self._textblob = None
        if enable_textblob:
            try:
                from textblob import TextBlob  # type: ignore

                self._textblob = TextBlob
            except Exception:
                self._textblob = None

    async def analyze(self, request: AnalyzeTextRequest) -> ProviderResult:
        return await asyncio.to_thread(self._analyze_sync, request)

    def _analyze_sync(self, request: AnalyzeTextRequest) -> ProviderResult:
        start = time.time()
        text = request.text or ""
        scores = self._analyzer.polarity_scores(text)
        vader_score = scores.get("compound", 0.0)

        combined_score = vader_score
        if self._textblob:
            try:
                blob_score = float(self._textblob(text).sentiment.polarity)
                combined_score = (vader_score + blob_score) / 2
            except Exception:
                combined_score = vader_score

        confidence = min(1.0, max(0.35, abs(combined_score)))
        processing_ms = int((time.time() - start) * 1000)

        return ProviderResult(
            sentiment_score=max(-1.0, min(1.0, combined_score)),
            confidence=confidence,
            model_version="vader-textblob" if self._textblob else "vader",
            processing_time_ms=processing_ms,
        )


class NeutralProvider:
    """Safe fallback that returns neutral sentiment when no providers are available."""

    name = "neutral"

    async def analyze(self, request: AnalyzeTextRequest) -> ProviderResult:  # pragma: no cover - trivial
        return ProviderResult(
            sentiment_score=0.0,
            confidence=0.0,
            model_version="neutral",
            processing_time_ms=0,
        )


def build_provider_stack() -> Tuple[object, VaderProvider]:
    """
    Build the primary provider (per SENTIMENT_PROVIDER) and a VADER fallback.

    Returns (primary_provider, fallback_provider).
    """
    settings = get_settings()
    try:
        fallback = VaderProvider(enable_textblob=settings.enable_textblob_fallback)
    except ProviderUnavailable as exc:
        logger.warning("VADER fallback unavailable, using neutral provider. %s", exc)
        fallback = NeutralProvider()

    provider_name = (settings.sentiment_provider or "google").lower()
    try:
        if provider_name == "google":
            primary = GoogleLanguageProvider(
                endpoint=settings.google_language_endpoint,
                model_version=settings.google_language_model_version,
                require_https=settings.require_https_outbound,
                allow_local_http=settings.allow_local_http_providers,
            )
        elif provider_name == "openai":
            primary = OpenAIProvider(
                api_key=settings.openai_api_key,
                base_url=settings.openai_base_url,
                model=settings.openai_model,
                timeout=settings.openai_timeout,
                require_https=settings.require_https_outbound,
                allow_local_http=settings.allow_local_http_providers,
            )
        elif provider_name == "ollama":
            primary = OllamaProvider(
                ollama_url=settings.ollama_url,
                default_model=settings.default_model,
                deep_analysis_model=settings.deep_analysis_model,
                timeout=settings.ollama_timeout,
                require_https=settings.require_https_outbound,
                allow_local_http=settings.allow_local_http_providers,
            )
        elif provider_name == "vader":
            primary = fallback
        else:
            raise ProviderUnavailable(f"Unknown provider: {provider_name}")
    except ProviderUnavailable as exc:
        logger.warning(
            "Primary sentiment provider unavailable (%s). Falling back to VADER.",
            exc,
        )
        primary = fallback

    return primary, fallback
