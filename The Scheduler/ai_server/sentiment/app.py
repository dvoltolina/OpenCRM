"""
FastAPI application for sentiment analysis service.
Designed for deployment on cloud GPU (RunPod, Lambda Labs).

Agent AI-6: Python Sentiment Service (Ollama LLM)

HIPAA COMPLIANCE:
- All requests are authenticated (when require_authentication=True)
- Multi-tenant isolation enforced via SecurityContext
- All analyses logged to audit trail
- PHI sanitized from logs and optionally from responses
- Rate limiting to prevent abuse
"""
import logging
from datetime import datetime
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .schemas import (
    AnalyzeTextRequest,
    SentimentResultResponse,
    BatchAnalyzeRequest,
    BatchAnalyzeResponse,
    HealthStatus,
    RiskIndicator,
)
from .analyzer import SentimentAnalyzer
from .config import get_settings
from .security import (
    SecurityContext,
    get_security_context,
    require_tenant_access,
    RequestIdMiddleware,
    TransportSecurityMiddleware,
)
from .audit import audit_logger
from .providers import build_provider_stack
from .risk_keywords import RiskKeywordMatcher
from .ollama_client import get_gpu_info

# Configure logging
settings = get_settings()
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Global instances
analyzer: SentimentAnalyzer = None
server_start_time: datetime = None
active_provider_name: str = "unknown"
using_fallback_provider: bool = False


def _validate_cors_configuration() -> None:
    """Ensure CORS settings are secure (no wildcards, HTTPS origins in prod)."""
    if "*" in settings.allowed_origins:
        raise ValueError("Wildcard CORS origin is not allowed")

    if settings.require_https:
        insecure_origins = [
            origin
            for origin in settings.allowed_origins
            if origin.startswith("http://") and "localhost" not in origin
        ]
        if insecure_origins:
            raise ValueError(
                f"Insecure CORS origins configured while HTTPS is required: {insecure_origins}"
            )


def redact_phi_from_result(result: SentimentResultResponse) -> SentimentResultResponse:
    """
    Redact PHI from a sentiment result if configured.

    HIPAA: Minimize PHI in responses when redact_trigger_text is enabled.
    """
    settings = get_settings()

    # Truncate analyzed text to configured length
    truncated_text = result.analyzed_text[: settings.max_analyzed_text_length]
    if settings.max_analyzed_text_length <= 0:
        truncated_text = "[REDACTED]"
    elif len(result.analyzed_text) > settings.max_analyzed_text_length:
        truncated_text += "..."

    # Optionally redact trigger_text from indicators
    risk_indicators = result.risk_indicators
    vip_indicators = result.vip_indicators

    if settings.redact_trigger_text:
        risk_indicators = [
            RiskIndicator(
                id=ind.id,
                type=ind.type,
                severity=ind.severity,
                category=ind.category,
                description=ind.description,
                confidence=ind.confidence,
                source=ind.source,
                source_document_id=ind.source_document_id,
                trigger_text="[REDACTED]" if ind.trigger_text else None,
                detected_at=ind.detected_at,
                suggested_action=ind.suggested_action,
            )
            for ind in risk_indicators
        ]
        vip_indicators = [
            RiskIndicator(
                id=ind.id,
                type=ind.type,
                severity=ind.severity,
                category=ind.category,
                description=ind.description,
                confidence=ind.confidence,
                source=ind.source,
                source_document_id=ind.source_document_id,
                trigger_text="[REDACTED]" if ind.trigger_text else None,
                detected_at=ind.detected_at,
                suggested_action=ind.suggested_action,
            )
            for ind in vip_indicators
        ]

    return SentimentResultResponse(
        id=result.id,
        business_id=result.business_id,
        client_id=result.client_id,
        source=result.source,
        source_document_id=result.source_document_id,
        analyzed_text=truncated_text,
        sentiment_score=result.sentiment_score,
        confidence=result.confidence,
        risk_indicators=risk_indicators,
        vip_indicators=vip_indicators,
        summary=None if settings.redact_summary else result.summary,
        recommended_action=None
        if settings.redact_recommended_action
        else result.recommended_action,
        model_version=result.model_version,
        analyzed_at=result.analyzed_at,
        expires_at=result.expires_at,
        processing_time_ms=result.processing_time_ms,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    global analyzer, server_start_time, active_provider_name, using_fallback_provider

    # Startup
    logger.info("Starting sentiment analysis service...")
    logger.info(f"HIPAA Mode: Authentication {'ENABLED' if settings.require_authentication else 'DISABLED'}")
    logger.info(f"HIPAA Mode: Audit logging {'ENABLED' if settings.enable_audit_logging else 'DISABLED'}")
    logger.info(f"HIPAA Mode: PHI redaction {'ENABLED' if settings.redact_trigger_text else 'DISABLED'}")

    server_start_time = datetime.now()

    # Initialize provider stack
    primary_provider, fallback_provider = build_provider_stack()
    active_provider_name = getattr(primary_provider, "name", "unknown")
    using_fallback_provider = primary_provider is fallback_provider

    analyzer = SentimentAnalyzer(
        provider=primary_provider,
        fallback_provider=fallback_provider,
        risk_matcher=RiskKeywordMatcher(),
        result_ttl_hours=settings.result_ttl_hours,
    )

    logger.info(
        "Sentiment service ready with provider=%s fallback=%s",
        active_provider_name,
        getattr(fallback_provider, "name", "vader"),
    )

    yield

    # Shutdown
    logger.info("Shutting down sentiment service...")
    if hasattr(primary_provider, "_client") and hasattr(primary_provider._client, "close"):
        close_fn = getattr(primary_provider._client, "close")
        if callable(close_fn):
            try:
                await close_fn()
            except Exception:
                pass


# Validate CORS settings before app instantiation
_validate_cors_configuration()

app = FastAPI(
    title="The Scheduler - Sentiment Analysis Service",
    description="AI-powered sentiment analysis for customer communications (HIPAA Compliant)",
    version="1.0.0",
    lifespan=lifespan,
)

# Add request ID middleware for audit correlation
app.add_middleware(RequestIdMiddleware)
app.add_middleware(TransportSecurityMiddleware)

# CORS middleware - HIPAA: Restrict to known origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=settings.allowed_headers,
)


# ============ Health Endpoints ============


@app.get("/health", response_model=HealthStatus)
async def health_check():
    """Detailed health status."""
    uptime = (
        (datetime.now() - server_start_time).total_seconds()
        if server_start_time
        else 0
    )

    gpu_info = get_gpu_info()
    provider_ready = analyzer is not None
    status = "degraded" if using_fallback_provider else "healthy"

    return HealthStatus(
        status=status,
        ollama_connected=provider_ready,
        model_loaded=active_provider_name,
        models_available=[],
        uptime_seconds=uptime,
        total_analyses=analyzer.analysis_count if analyzer else 0,
        avg_latency_ms=0,
        gpu_available=gpu_info["available"],
        gpu_memory_used_mb=gpu_info.get("memory_used_mb"),
        provider=active_provider_name,
        using_fallback=using_fallback_provider,
    )


@app.get("/health/ready")
async def readiness_check():
    """Kubernetes-style readiness probe."""
    if ollama_client and await ollama_client.check_connection():
        return {"status": "ready"}
    raise HTTPException(status_code=503, detail="Ollama not ready")


@app.get("/health/live")
async def liveness_check():
    """Kubernetes-style liveness probe."""
    return {"status": "alive"}


# ============ Analysis Endpoints ============


@app.post("/analyze/sentiment", response_model=SentimentResultResponse)
async def analyze_sentiment(
    request: AnalyzeTextRequest,
    security: SecurityContext = Depends(get_security_context),
):
    """
    Analyze a single text for sentiment.

    Returns sentiment score, risk indicators, and VIP indicators.

    HIPAA: Requires authentication and logs to audit trail.
    """
    if not analyzer:
        raise HTTPException(status_code=503, detail="Analyzer not initialized")

    # HIPAA: Validate tenant access
    require_tenant_access(security, request.business_id)

    try:
        result = await analyzer.analyze(request)

        # HIPAA: Redact PHI from response if configured
        result = redact_phi_from_result(result)
        provider_name = (result.model_version or "unknown").split(":")[0]

        # HIPAA: Log to audit trail (no PHI in logs)
        if settings.enable_audit_logging:
            audit_logger.log_sentiment_analysis(
                business_id=request.business_id,
                client_id=request.client_id,
                source=request.source.value,
                endpoint="/analyze/sentiment",
                status_code=status.HTTP_200_OK,
                provider=provider_name,
                sentiment_score=result.sentiment_score,
                confidence=result.confidence,
                risk_indicator_count=len(result.risk_indicators),
                vip_indicator_count=len(result.vip_indicators),
                model_version=result.model_version,
                processing_time_ms=result.processing_time_ms or 0,
                request_id=security.request_id,
                user_id=security.user_id,
            )

        # Log without PHI - only metadata
        logger.info(
            "[%s] sentiment complete provider=%s business=%s source=%s text_length=%s risks=%s vips=%s",
            security.request_id,
            provider_name,
            request.business_id,
            request.source.value,
            len(request.text),
            len(result.risk_indicators),
            len(result.vip_indicators),
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        # HIPAA: Log failure without PHI
        if settings.enable_audit_logging:
            provider_name = active_provider_name
            audit_logger.log_analysis_failure(
                business_id=request.business_id,
                client_id=request.client_id,
                error_type=type(e).__name__,
                endpoint="/analyze/sentiment",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                provider=provider_name,
                request_id=security.request_id,
            )
        logger.error(f"[{security.request_id}] Analysis failed: {type(e).__name__}")
        raise HTTPException(status_code=500, detail="Analysis failed")


@app.post("/analyze/sentiment/batch", response_model=BatchAnalyzeResponse)
async def analyze_sentiment_batch(
    request: BatchAnalyzeRequest,
    security: SecurityContext = Depends(get_security_context),
):
    """
    Analyze multiple texts for sentiment.

    More efficient than calling /analyze/sentiment multiple times.

    HIPAA: Requires authentication, validates tenant access for all texts,
    and logs to audit trail.
    """
    if not analyzer:
        raise HTTPException(status_code=503, detail="Analyzer not initialized")

    if len(request.texts) > settings.max_batch_size:
        raise HTTPException(
            status_code=400,
            detail=f"Batch size exceeds maximum of {settings.max_batch_size}",
        )

    # HIPAA: Validate tenant access for ALL texts in batch
    for text_request in request.texts:
        require_tenant_access(security, text_request.business_id)

    start_time = datetime.now()

    try:
        results = await analyzer.analyze_batch(request.texts)

        processing_time = (datetime.now() - start_time).total_seconds() * 1000

        # HIPAA: Redact PHI from all results
        results = [redact_phi_from_result(r) for r in results]

        # Separate successful and failed
        successful = [r for r in results if r.model_version != "error"]
        errors = [
            {"text_id": r.id, "error": "Analysis failed"}  # Don't include actual error
            for r in results
            if r.model_version == "error"
        ]

        # HIPAA: Log batch to audit trail
        if settings.enable_audit_logging:
            # Get unique business_id (should all be same due to tenant validation)
            business_ids = set(t.business_id for t in request.texts)
            provider_name = (
                (successful[0].model_version or "unknown").split(":")[0]
                if successful
                else active_provider_name
            )
            for bid in business_ids:
                audit_logger.log_batch_analysis(
                    business_id=bid,
                    endpoint="/analyze/sentiment/batch",
                    status_code=status.HTTP_200_OK,
                    provider=provider_name,
                    total_texts=len(request.texts),
                    successful_count=len(successful),
                    error_count=len(errors),
                    processing_time_ms=processing_time,
                    request_id=security.request_id,
                    user_id=security.user_id,
                )

        logger.info(
            f"[{security.request_id}] Batch analysis: "
            f"processed={len(results)}, "
            f"successful={len(successful)}, "
            f"errors={len(errors)}, "
            f"time_ms={processing_time:.1f}"
        )

        return BatchAnalyzeResponse(
            results=successful,
            total_processed=len(results),
            processing_time_ms=processing_time,
            errors=errors,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[{security.request_id}] Batch analysis failed: {type(e).__name__}")
        raise HTTPException(status_code=500, detail="Batch analysis failed")


# ============ Error Handlers ============


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Global exception handler for unhandled errors.

    HIPAA: Never expose internal error details that might contain PHI.
    """
    # Log error type only, not message (might contain PHI)
    logger.error(f"Unhandled exception: {type(exc).__name__}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# ============ Main Entry Point ============


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
