"""
Demand Forecasting API Service.

FastAPI application providing demand forecasting endpoints.
HIPAA-compliant with JWT auth, tenant isolation, and audit logging.

Agent AI-21: Waitlist Intelligence & Demand Forecasting
"""
import logging
from datetime import datetime
from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field

from .config import get_settings
from .demand_predictor import PROPHET_AVAILABLE, create_predictor, DemandPredictor
from .security import (
    RequestIdMiddleware,
    SecurityContext,
    SecurityHeadersMiddleware,
    TransportSecurityMiddleware,
    get_security_context,
    require_tenant_access,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

app = FastAPI(
    title="Demand Forecasting API",
    description="HIPAA-compliant time series forecasting for booking demand",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Security middleware
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(TransportSecurityMiddleware)
app.add_middleware(RequestIdMiddleware)


# Request/Response Models
class HistoricalDataPoint(BaseModel):
    """Single historical data point."""

    date: str = Field(..., description="Date in YYYY-MM-DD format")
    count: int = Field(..., ge=0, description="Booking count for the day")


class ForecastRequest(BaseModel):
    """Forecast request."""

    business_id: str = Field(..., description="Business identifier")
    location_id: Optional[str] = Field(None, description="Optional location filter")
    service_id: Optional[str] = Field(None, description="Optional service filter")
    forecast_days: int = Field(30, ge=1, le=90, description="Days to forecast")
    historical_data: List[HistoricalDataPoint] = Field(
        ..., min_length=7, description="At least 7 days of historical data"
    )


class DailyForecastResponse(BaseModel):
    """Single day forecast response."""

    date: str
    predicted: float
    lower_bound: float
    upper_bound: float
    demand_level: str
    confidence: float
    day_of_week: int
    is_holiday: bool
    holiday_name: Optional[str]


class ForecastResponse(BaseModel):
    """Complete forecast response."""

    forecasts: List[DailyForecastResponse]
    average: float
    model_version: str
    generated_at: str
    request_id: str


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    timestamp: str
    prophet_available: bool


# Cache for predictors (keyed by business_id)
_predictor_cache: dict[str, tuple[DemandPredictor, datetime]] = {}
CACHE_TTL_HOURS = 6


def _get_cached_predictor(
    business_id: str, historical_data: List[HistoricalDataPoint]
) -> DemandPredictor:
    """Get or create cached predictor."""
    cache_key = business_id
    now = datetime.utcnow()

    if cache_key in _predictor_cache:
        predictor, cached_at = _predictor_cache[cache_key]
        age_hours = (now - cached_at).total_seconds() / 3600
        if age_hours < CACHE_TTL_HOURS:
            return predictor

    data = [{"date": p.date, "count": p.count} for p in historical_data]
    predictor = create_predictor(data)
    _predictor_cache[cache_key] = (predictor, now)
    return predictor


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check(
    security: SecurityContext = Depends(get_security_context),
):
    """
    Health check endpoint.

    Requires authentication in production for HIPAA compliance.
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        prophet_available=PROPHET_AVAILABLE,
    )


@app.post("/api/v1/forecast", response_model=ForecastResponse, tags=["Forecasting"])
async def generate_forecast(
    request: ForecastRequest,
    security: SecurityContext = Depends(get_security_context),
):
    """
    Generate demand forecast.

    Requires authentication and validates tenant access.
    The business_id in the request must match the authenticated tenant.
    """
    # HIPAA: Validate tenant access
    require_tenant_access(security, request.business_id)

    try:
        predictor = _get_cached_predictor(request.business_id, request.historical_data)
        result = predictor.predict(forecast_days=request.forecast_days)

        logger.info(
            "Forecast generated",
            extra={
                "event": "forecast_generated",
                "business_id": request.business_id,
                "forecast_days": request.forecast_days,
                "request_id": security.request_id,
                "user_id": security.user_id,
            },
        )

        return ForecastResponse(
            forecasts=[
                DailyForecastResponse(
                    date=f.date.strftime("%Y-%m-%d"),
                    predicted=f.predicted,
                    lower_bound=f.lower_bound,
                    upper_bound=f.upper_bound,
                    demand_level=f.demand_level.value,
                    confidence=f.confidence,
                    day_of_week=f.day_of_week,
                    is_holiday=f.is_holiday,
                    holiday_name=f.holiday_name,
                )
                for f in result.forecasts
            ],
            average=result.average,
            model_version=result.model_version,
            generated_at=result.generated_at.isoformat(),
            request_id=security.request_id,
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(
            "Forecast generation failed",
            extra={
                "event": "forecast_error",
                "business_id": request.business_id,
                "request_id": security.request_id,
            },
        )
        raise HTTPException(status_code=500, detail="Forecast generation failed")


@app.post("/api/v1/forecast/clear-cache", tags=["Forecasting"])
async def clear_cache(
    business_id: Optional[str] = None,
    security: SecurityContext = Depends(get_security_context),
):
    """
    Clear predictor cache.

    If business_id provided, clears only that business (requires tenant access).
    Admin-only operation for clearing all caches.
    """
    if business_id:
        # Validate tenant access for specific business
        require_tenant_access(security, business_id)

        if business_id in _predictor_cache:
            del _predictor_cache[business_id]
            logger.info(
                "Cache cleared",
                extra={
                    "event": "cache_cleared",
                    "business_id": business_id,
                    "request_id": security.request_id,
                },
            )
            return {"cleared": 1, "business_id": business_id}
        return {"cleared": 0, "business_id": business_id}
    else:
        # Clearing all caches requires admin (business_id=None in context)
        if security.business_id is not None:
            raise HTTPException(
                status_code=403, detail="Admin access required to clear all caches"
            )

        count = len(_predictor_cache)
        _predictor_cache.clear()
        logger.info(
            "All caches cleared",
            extra={
                "event": "cache_cleared_all",
                "count": count,
                "request_id": security.request_id,
            },
        )
        return {"cleared": count}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=settings.host, port=settings.port)
