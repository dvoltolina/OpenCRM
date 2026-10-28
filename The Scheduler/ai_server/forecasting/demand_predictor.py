"""
Demand Forecasting Service using Facebook Prophet.

Predicts daily booking volume for staffing optimization.
Handles weekly patterns, holidays, and seasonality.

Agent AI-21: Waitlist Intelligence & Demand Forecasting
"""

import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

import pandas as pd
import numpy as np

try:
    from prophet import Prophet
    PROPHET_AVAILABLE = True
except ImportError:
    PROPHET_AVAILABLE = False
    logging.warning("Prophet not installed. Using fallback forecasting.")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DemandLevel(Enum):
    """Demand level classification."""
    VERY_LOW = "very_low"
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    VERY_HIGH = "very_high"


@dataclass
class DailyForecast:
    """Single day forecast."""
    date: datetime
    predicted: float
    lower_bound: float
    upper_bound: float
    demand_level: DemandLevel
    confidence: float
    day_of_week: int
    is_holiday: bool = False
    holiday_name: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "date": self.date.strftime("%Y-%m-%d"),
            "predicted": round(self.predicted, 1),
            "lower_bound": round(self.lower_bound, 1),
            "upper_bound": round(self.upper_bound, 1),
            "demand_level": self.demand_level.value,
            "confidence": round(self.confidence, 2),
            "day_of_week": self.day_of_week,
            "is_holiday": self.is_holiday,
            "holiday_name": self.holiday_name,
        }


@dataclass
class ForecastResult:
    """Complete forecast result."""
    forecasts: List[DailyForecast]
    average: float
    model_version: str
    generated_at: datetime = field(default_factory=datetime.utcnow)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "forecasts": [f.to_dict() for f in self.forecasts],
            "average": round(self.average, 1),
            "model_version": self.model_version,
            "generated_at": self.generated_at.isoformat(),
        }


class DemandPredictor:
    """
    Demand forecasting using Facebook Prophet.

    Features:
    - Weekly seasonality detection
    - Holiday effects
    - Uncertainty intervals
    - Trend detection
    """

    # US Federal Holidays (can be extended)
    US_HOLIDAYS = [
        {"holiday": "New Year's Day", "ds": "2024-01-01"},
        {"holiday": "MLK Day", "ds": "2024-01-15"},
        {"holiday": "Presidents' Day", "ds": "2024-02-19"},
        {"holiday": "Memorial Day", "ds": "2024-05-27"},
        {"holiday": "Independence Day", "ds": "2024-07-04"},
        {"holiday": "Labor Day", "ds": "2024-09-02"},
        {"holiday": "Veterans Day", "ds": "2024-11-11"},
        {"holiday": "Thanksgiving", "ds": "2024-11-28"},
        {"holiday": "Christmas", "ds": "2024-12-25"},
        # 2025
        {"holiday": "New Year's Day", "ds": "2025-01-01"},
        {"holiday": "MLK Day", "ds": "2025-01-20"},
        {"holiday": "Presidents' Day", "ds": "2025-02-17"},
        {"holiday": "Memorial Day", "ds": "2025-05-26"},
        {"holiday": "Independence Day", "ds": "2025-07-04"},
        {"holiday": "Labor Day", "ds": "2025-09-01"},
        {"holiday": "Veterans Day", "ds": "2025-11-11"},
        {"holiday": "Thanksgiving", "ds": "2025-11-27"},
        {"holiday": "Christmas", "ds": "2025-12-25"},
    ]

    def __init__(
        self,
        seasonality_mode: str = "multiplicative",
        yearly_seasonality: bool = False,
        weekly_seasonality: bool = True,
        daily_seasonality: bool = False,
        interval_width: float = 0.80,
    ):
        """
        Initialize predictor.

        Args:
            seasonality_mode: 'additive' or 'multiplicative'
            yearly_seasonality: Include yearly patterns
            weekly_seasonality: Include weekly patterns
            daily_seasonality: Include daily patterns
            interval_width: Confidence interval width (0-1)
        """
        self.seasonality_mode = seasonality_mode
        self.yearly_seasonality = yearly_seasonality
        self.weekly_seasonality = weekly_seasonality
        self.daily_seasonality = daily_seasonality
        self.interval_width = interval_width
        self._model: Optional[Prophet] = None
        self._average: float = 0.0

    def fit(self, historical_data: List[Dict[str, Any]]) -> "DemandPredictor":
        """
        Fit model on historical data.

        Args:
            historical_data: List of {"date": "YYYY-MM-DD", "count": int}

        Returns:
            Self for chaining
        """
        if not historical_data:
            logger.warning("No historical data provided")
            return self

        # Convert to DataFrame
        df = pd.DataFrame(historical_data)
        df["ds"] = pd.to_datetime(df["date"])
        df["y"] = df["count"].astype(float)
        df = df[["ds", "y"]]

        # Store average for demand classification
        self._average = df["y"].mean()

        if not PROPHET_AVAILABLE:
            logger.warning("Prophet not available, will use fallback")
            self._historical_df = df
            return self

        # Create Prophet model
        self._model = Prophet(
            seasonality_mode=self.seasonality_mode,
            yearly_seasonality=self.yearly_seasonality,
            weekly_seasonality=self.weekly_seasonality,
            daily_seasonality=self.daily_seasonality,
            interval_width=self.interval_width,
        )

        # Add holidays
        holidays_df = pd.DataFrame(self.US_HOLIDAYS)
        holidays_df["ds"] = pd.to_datetime(holidays_df["ds"])
        self._model.holidays = holidays_df

        # Fit model
        self._model.fit(df)

        logger.info(f"Model fitted on {len(df)} data points, average: {self._average:.1f}")
        return self

    def predict(self, forecast_days: int = 30) -> ForecastResult:
        """
        Generate forecast.

        Args:
            forecast_days: Number of days to forecast

        Returns:
            ForecastResult with daily predictions
        """
        if PROPHET_AVAILABLE and self._model is not None:
            return self._prophet_predict(forecast_days)
        else:
            return self._fallback_predict(forecast_days)

    def _prophet_predict(self, forecast_days: int) -> ForecastResult:
        """Generate forecast using Prophet."""
        # Create future dataframe
        future = self._model.make_future_dataframe(periods=forecast_days)

        # Predict
        forecast = self._model.predict(future)

        # Get only future dates
        today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        future_forecast = forecast[forecast["ds"] >= today].tail(forecast_days)

        # Convert to DailyForecast objects
        forecasts = []
        holidays_dict = {
            pd.to_datetime(h["ds"]).date(): h["holiday"]
            for h in self.US_HOLIDAYS
        }

        for _, row in future_forecast.iterrows():
            date = row["ds"].to_pydatetime()
            predicted = max(0, row["yhat"])
            lower = max(0, row["yhat_lower"])
            upper = max(0, row["yhat_upper"])

            # Check if holiday
            is_holiday = date.date() in holidays_dict
            holiday_name = holidays_dict.get(date.date())

            # Calculate confidence from interval width
            confidence = self._calculate_confidence(lower, upper, predicted)

            forecasts.append(DailyForecast(
                date=date,
                predicted=predicted,
                lower_bound=lower,
                upper_bound=upper,
                demand_level=self._classify_demand(predicted),
                confidence=confidence,
                day_of_week=date.isoweekday(),
                is_holiday=is_holiday,
                holiday_name=holiday_name,
            ))

        return ForecastResult(
            forecasts=forecasts,
            average=self._average,
            model_version="prophet-1.0",
        )

    def _fallback_predict(self, forecast_days: int) -> ForecastResult:
        """Generate forecast using simple averaging fallback."""
        logger.info("Using fallback forecasting method")

        # If we have historical data, use day-of-week averages
        if hasattr(self, "_historical_df") and not self._historical_df.empty:
            df = self._historical_df
            df["dow"] = df["ds"].dt.dayofweek
            dow_avg = df.groupby("dow")["y"].mean().to_dict()
            overall_avg = df["y"].mean()
        else:
            # Default values
            dow_avg = {}
            overall_avg = 10.0
            self._average = overall_avg

        # Generate forecasts
        forecasts = []
        today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

        for i in range(forecast_days):
            date = today + timedelta(days=i)
            dow = date.weekday()

            predicted = dow_avg.get(dow, overall_avg)
            margin = predicted * 0.25  # 25% margin

            forecasts.append(DailyForecast(
                date=date,
                predicted=predicted,
                lower_bound=max(0, predicted - margin),
                upper_bound=predicted + margin,
                demand_level=self._classify_demand(predicted),
                confidence=0.6,  # Lower confidence for fallback
                day_of_week=date.isoweekday(),
            ))

        return ForecastResult(
            forecasts=forecasts,
            average=self._average,
            model_version="fallback-1.0",
        )

    def _classify_demand(self, predicted: float) -> DemandLevel:
        """Classify demand level relative to average."""
        if self._average <= 0:
            return DemandLevel.NORMAL

        ratio = predicted / self._average

        if ratio < 0.25:
            return DemandLevel.VERY_LOW
        elif ratio < 0.75:
            return DemandLevel.LOW
        elif ratio < 1.25:
            return DemandLevel.NORMAL
        elif ratio < 1.75:
            return DemandLevel.HIGH
        else:
            return DemandLevel.VERY_HIGH

    def _calculate_confidence(
        self,
        lower: float,
        upper: float,
        predicted: float
    ) -> float:
        """Calculate confidence score from interval."""
        if predicted <= 0:
            return 0.5

        relative_width = (upper - lower) / predicted
        # Narrower interval = higher confidence
        return max(0.3, min(0.95, 1 - relative_width / 2))


def create_predictor(
    historical_data: List[Dict[str, Any]],
    **kwargs
) -> DemandPredictor:
    """
    Factory function to create and fit a predictor.

    Args:
        historical_data: List of {"date": "YYYY-MM-DD", "count": int}
        **kwargs: Additional arguments for DemandPredictor

    Returns:
        Fitted DemandPredictor
    """
    predictor = DemandPredictor(**kwargs)
    predictor.fit(historical_data)
    return predictor


# Example usage
if __name__ == "__main__":
    # Sample historical data
    sample_data = []
    base_date = datetime.now() - timedelta(days=90)

    for i in range(90):
        date = base_date + timedelta(days=i)
        dow = date.weekday()
        # Simulate weekly pattern
        base_count = 15 if dow < 5 else 8  # Lower on weekends
        noise = np.random.normal(0, 2)
        count = max(0, int(base_count + noise))

        sample_data.append({
            "date": date.strftime("%Y-%m-%d"),
            "count": count,
        })

    # Create and fit predictor
    predictor = create_predictor(sample_data)

    # Generate forecast
    result = predictor.predict(forecast_days=14)

    print(f"Model: {result.model_version}")
    print(f"Average: {result.average:.1f}")
    print("\nForecasts:")
    for f in result.forecasts:
        print(f"  {f.date.strftime('%Y-%m-%d %a')}: "
              f"{f.predicted:.0f} ({f.lower_bound:.0f}-{f.upper_bound:.0f}) "
              f"- {f.demand_level.value}")
