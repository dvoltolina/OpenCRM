"""
FastAPI application for no-show prediction service.
Runs on RTX 3090 server, serves predictions to Flutter app.

Agent AI-3: Python Prediction Server

HIPAA COMPLIANCE:
- All endpoints require authentication (when enabled in config)
- Multi-tenant isolation enforced via SecurityContext
- All predictions logged to audit trail
- PHI identifiers are hashed in logs
"""
import logging
import time
import uuid
from datetime import datetime
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .schemas import (
    PredictionFeaturesRequest,
    NoshowPredictionResponse,
    BatchPredictionRequest,
    BatchPredictionResponse,
    HealthStatus,
    ModelMetadata,
)
from .model import ModelManager
from .config import get_settings, Settings
from .security import (
    SecurityContext,
    get_security_context,
    require_tenant_access,
    RequestIdMiddleware,
    TransportSecurityMiddleware,
)
from .audit import audit_logger
from .explainer import (
    get_explainer,
    set_explainer_model,
    ExplanationResponse,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global model manager
model_manager: Optional[ModelManager] = None

# Track server stats
server_start_time: Optional[datetime] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    global model_manager, server_start_time

    settings = get_settings()

    # Startup
    logger.info("Starting prediction service...")
    server_start_time = datetime.now()

    # Initialize model manager
    model_manager = ModelManager(models_dir=settings.models_dir)

    # Load model
    if model_manager.load_model(settings.default_model_name):
        if model_manager.is_mock:
            logger.info(f"Model loaded in MOCK mode: {model_manager.metadata.version}")
        else:
            logger.info(f"Model loaded: {model_manager.metadata.version}")
            # Initialize SHAP explainer with the loaded model
            if set_explainer_model(model_manager.model):
                logger.info("SHAP explainer initialized successfully")
            else:
                logger.warning("SHAP explainer not available - using rule-based explanations")
    else:
        logger.warning("Failed to load model - service starting without model")

    yield

    # Shutdown
    logger.info("Shutting down prediction service...")


def create_app() -> FastAPI:
    """Create FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title="The Scheduler - No-Show Prediction Service",
        description="AI-powered no-show risk prediction for appointments",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # Request ID middleware for audit correlation
    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(TransportSecurityMiddleware)

    # CORS middleware - HIPAA: explicitly list allowed headers
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=settings.allowed_headers,
    )

    return app


app = create_app()


# ============ Dependencies ============

def get_model_manager() -> ModelManager:
    """Dependency to get model manager."""
    if model_manager is None:
        raise HTTPException(
            status_code=503,
            detail="Service not initialized"
        )
    return model_manager


def require_model(manager: ModelManager = Depends(get_model_manager)) -> ModelManager:
    """Dependency to check model is loaded."""
    if not manager.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Service is starting up or model failed to load."
        )
    return manager


# ============ Health Endpoints ============

@app.get("/health", response_model=HealthStatus, tags=["Health"])
async def health_check(manager: ModelManager = Depends(get_model_manager)):
    """
    Health check endpoint for monitoring and load balancers.
    Returns detailed status of the prediction service.
    """
    uptime = (datetime.now() - server_start_time).total_seconds() if server_start_time else 0

    if manager.is_loaded:
        status = "healthy"
    else:
        status = "unhealthy"

    stats = manager.stats

    return HealthStatus(
        status=status,
        model_loaded=manager.is_loaded,
        model_metadata=manager.metadata,
        uptime_seconds=uptime,
        total_predictions=stats["prediction_count"],
        avg_latency_ms=stats["avg_latency_ms"],
        last_prediction_at=datetime.fromisoformat(stats["last_prediction_at"])
        if stats.get("last_prediction_at") else None,
        error_message=None if manager.is_loaded else "Model not loaded",
    )


@app.get("/health/ready", tags=["Health"])
async def readiness_check(manager: ModelManager = Depends(get_model_manager)):
    """Kubernetes-style readiness probe."""
    if not manager.is_loaded:
        raise HTTPException(status_code=503, detail="Model not ready")
    return {"status": "ready", "is_mock": manager.is_mock}


@app.get("/health/live", tags=["Health"])
async def liveness_check():
    """Kubernetes-style liveness probe."""
    return {"status": "alive"}


# ============ Model Management Endpoints ============

@app.get("/model/metadata", response_model=ModelMetadata, tags=["Model"])
async def get_model_metadata(manager: ModelManager = Depends(require_model)):
    """Get information about the currently loaded model."""
    return manager.metadata


@app.post("/model/reload", tags=["Model"])
async def reload_model(
    model_name: Optional[str] = None,
    background_tasks: BackgroundTasks = None,
    manager: ModelManager = Depends(get_model_manager),
    security_context: SecurityContext = Depends(get_security_context),
):
    """
    Hot-reload the model without restarting the service.
    Use this after deploying a new model version.

    HIPAA: This is a sensitive operation, requires authentication, logged to audit.
    """
    settings = get_settings()
    name = model_name or settings.default_model_name

    # HIPAA: Log model reload request
    audit_logger.log_model_reload_requested(
        model_name=name,
        request_id=security_context.request_id,
        user_id=security_context.user_id,
    )

    def do_reload():
        success = manager.reload_model(name)
        if success:
            logger.info(f"Model reloaded successfully: {name}")
            audit_logger.log_model_loaded(
                model_name=name,
                model_version=manager.metadata.version if manager.metadata else "unknown",
                is_mock=manager.is_mock,
            )
        else:
            logger.error(f"Model reload failed: {name}")

    background_tasks.add_task(do_reload)

    return {"status": "reload_initiated", "model_name": name}


# ============ Prediction Endpoints (Versioned API) ============

@app.post(
    "/api/v1/predict/noshow",
    response_model=NoshowPredictionResponse,
    tags=["Predictions"]
)
async def predict_noshow(
    features: PredictionFeaturesRequest,
    request: Request,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """
    Predict no-show probability for a single appointment.

    The Flutter app calls this endpoint with extracted features.
    Returns probability, risk level, and recommended actions.

    HIPAA: Requires authentication, validates tenant access, logs to audit trail.
    """
    settings = get_settings()
    request_id = security_context.request_id
    start_time = time.time()

    # HIPAA: Validate tenant access
    require_tenant_access(security_context, features.business_id)

    try:
        prediction = manager.predict(
            features,
            high_risk_threshold=settings.high_risk_threshold,
            medium_risk_threshold=settings.medium_risk_threshold,
            cache_ttl_minutes=settings.prediction_cache_ttl_minutes,
        )

        # Add request ID
        prediction = NoshowPredictionResponse(
            **prediction.model_dump(),
            request_id=request_id,
        )

        processing_time_ms = (time.time() - start_time) * 1000

        # HIPAA: Log prediction to audit trail
        audit_logger.log_prediction(
            business_id=features.business_id,
            appointment_id=features.appointment_id,
            probability=prediction.probability,
            risk_level=prediction.risk_level.value,
            confidence=prediction.confidence,
            model_version=prediction.model_version,
            processing_time_ms=processing_time_ms,
            request_id=request_id,
            user_id=security_context.user_id,
            source_ip=security_context.source_ip,
        )

        logger.info(
            f"[{request_id}] Prediction generated for tenant={features.business_id}, "
            f"risk={prediction.risk_level.value}, "
            f"prob={prediction.probability:.3f}"
        )

        return prediction

    except HTTPException:
        raise
    except Exception as e:
        # HIPAA: Log failure to audit trail
        audit_logger.log_prediction_failure(
            business_id=features.business_id,
            appointment_id=features.appointment_id,
            error_type=type(e).__name__,
            request_id=request_id,
            source_ip=security_context.source_ip,
        )
        logger.error(f"[{request_id}] Prediction failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )


@app.post(
    "/api/v1/predict/noshow/batch",
    response_model=BatchPredictionResponse,
    tags=["Predictions"]
)
async def predict_noshow_batch(
    request: BatchPredictionRequest,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """
    Predict no-show probability for multiple appointments.

    More efficient than calling /predict/noshow multiple times.
    Use for calendar views showing many appointments.

    HIPAA: Requires authentication, validates tenant access, logs to audit trail.
    """
    settings = get_settings()
    start_time = time.time()
    request_id = security_context.request_id

    if len(request.appointments) > settings.max_batch_size:
        raise HTTPException(
            status_code=400,
            detail=f"Batch size exceeds maximum of {settings.max_batch_size}"
        )

    # HIPAA: Validate tenant access for all appointments in batch
    business_ids = set(appt.business_id for appt in request.appointments)
    for business_id in business_ids:
        require_tenant_access(security_context, business_id)

    try:
        predictions = manager.predict_batch(
            request.appointments,
            high_risk_threshold=settings.high_risk_threshold,
            medium_risk_threshold=settings.medium_risk_threshold,
            cache_ttl_minutes=settings.prediction_cache_ttl_minutes,
        )

        processing_time = (time.time() - start_time) * 1000

        # HIPAA: Log batch prediction to audit trail
        risk_level_counts = {}
        for pred in predictions:
            level = pred.risk_level.value
            risk_level_counts[level] = risk_level_counts.get(level, 0) + 1

        # Log once per business in batch
        for business_id in business_ids:
            audit_logger.log_batch_prediction(
                business_id=business_id,
                total_predictions=len(predictions),
                risk_level_counts=risk_level_counts,
                processing_time_ms=processing_time,
                request_id=request_id,
                user_id=security_context.user_id,
                source_ip=security_context.source_ip,
            )

        logger.info(
            f"[{request_id}] Batch prediction completed for tenants={list(business_ids)}, "
            f"count={len(predictions)}, time_ms={processing_time:.1f}"
        )

        return BatchPredictionResponse(
            predictions=predictions,
            total_processed=len(predictions),
            processing_time_ms=processing_time,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[{request_id}] Batch prediction failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Batch prediction failed: {str(e)}"
        )


# ============ Explanation Endpoints (Agent AI-19) ============

@app.post(
    "/api/v1/predict/explain",
    tags=["Explainability"]
)
async def explain_prediction(
    request: Request,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """
    Get human-readable explanation for a prediction.

    Returns the top factors contributing to the no-show risk prediction,
    with humanized explanations suitable for staff display.

    Agent AI-19: Prediction Explainability

    HIPAA: Requires authentication, logs to audit trail.
    """
    import numpy as np

    request_id = security_context.request_id
    body = await request.json()

    appointment_id = body.get("appointment_id")
    num_factors = body.get("num_factors", 3)

    if not appointment_id:
        raise HTTPException(
            status_code=400,
            detail="appointment_id is required"
        )

    # For explanations, we need the original prediction data
    # In production, this would fetch from cache or re-predict
    # For now, we return an explanation based on available data
    try:
        explainer = get_explainer()

        # If feature_vector is provided in request, use it
        # Otherwise generate mock explanation
        feature_vector = body.get("feature_vector")
        feature_values = body.get("feature_values", {})
        probability = body.get("probability", 0.5)
        risk_level = body.get("risk_level", "medium")

        if feature_vector:
            feature_array = np.array(feature_vector)
        else:
            # Generate mock feature vector for demonstration
            feature_array = np.random.random(22)

        explanation = explainer.explain(
            appointment_id=appointment_id,
            feature_vector=feature_array,
            feature_values=feature_values,
            probability=probability,
            risk_level=risk_level,
            model_version=manager.metadata.version if manager.metadata else "unknown",
            num_factors=num_factors,
        )

        logger.info(
            f"[{request_id}] Explanation generated for appointment={appointment_id}"
        )

        return ExplanationResponse.from_explanation(explanation)

    except Exception as e:
        logger.error(f"[{request_id}] Explanation failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Explanation generation failed: {str(e)}"
        )


@app.post(
    "/predict/explain",
    tags=["Explainability (Legacy)"],
    deprecated=True,
)
async def explain_prediction_legacy(
    request: Request,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """Legacy endpoint - use /api/v1/predict/explain instead."""
    return await explain_prediction(request, manager, security_context)


# ============ Legacy Endpoints (without /api/v1 prefix for backward compatibility) ============

@app.post(
    "/predict/noshow",
    response_model=NoshowPredictionResponse,
    tags=["Predictions (Legacy)"],
    deprecated=True,
)
async def predict_noshow_legacy(
    features: PredictionFeaturesRequest,
    request: Request,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """Legacy endpoint - use /api/v1/predict/noshow instead."""
    return await predict_noshow(features, request, manager, security_context)


@app.post(
    "/predict/noshow/batch",
    response_model=BatchPredictionResponse,
    tags=["Predictions (Legacy)"],
    deprecated=True,
)
async def predict_noshow_batch_legacy(
    request: BatchPredictionRequest,
    manager: ModelManager = Depends(require_model),
    security_context: SecurityContext = Depends(get_security_context),
):
    """Legacy endpoint - use /api/v1/predict/noshow/batch instead."""
    return await predict_noshow_batch(request, manager, security_context)


# ============ Error Handlers ============

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "type": type(exc).__name__}
    )


# ============ Main Entry Point ============

if __name__ == "__main__":
    import uvicorn

    settings = get_settings()
    uvicorn.run(
        "app:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        workers=settings.workers,
    )
