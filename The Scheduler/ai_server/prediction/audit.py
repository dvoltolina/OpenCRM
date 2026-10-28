"""
HIPAA-compliant audit logging for prediction service.

All AI predictions and automated actions MUST be logged here.
Logs are structured for compliance reporting and incident investigation.

Agent AI-3: Python Prediction Server (Security Enhancement)
"""
import logging
import json
import hashlib
from datetime import datetime
from typing import Optional, Dict, Any, List
from enum import Enum

logger = logging.getLogger("audit")


class AuditAction(str, Enum):
    """Auditable actions in the prediction service."""
    PREDICTION_GENERATED = "ai_prediction_generated"
    BATCH_PREDICTION_GENERATED = "ai_batch_prediction_generated"
    PREDICTION_FAILED = "ai_prediction_failed"
    UNAUTHORIZED_ACCESS = "unauthorized_access_attempt"
    INVALID_TENANT_ACCESS = "invalid_tenant_access_attempt"
    MODEL_LOADED = "model_loaded"
    MODEL_RELOAD_REQUESTED = "model_reload_requested"


def hash_identifier(identifier: str) -> str:
    """
    Hash an identifier for logging purposes.
    PHI identifiers should be hashed, not logged in plain text.
    """
    return hashlib.sha256(identifier.encode()).hexdigest()[:16]


class AuditLogger:
    """
    HIPAA-compliant audit logger.

    All entries include:
    - Timestamp (ISO 8601)
    - Action performed
    - Business ID (for tenant isolation verification)
    - Hashed appointment ID (PHI protection)
    - Request metadata (no PHI)
    - Outcome (success/failure)
    """

    def __init__(self, service_name: str = "prediction-service"):
        self.service_name = service_name
        self._configure_audit_logger()

    def _configure_audit_logger(self):
        """Configure a separate audit log handler."""
        audit_handler = logging.StreamHandler()
        audit_handler.setLevel(logging.INFO)
        audit_formatter = logging.Formatter(
            '{"timestamp": "%(asctime)s", "level": "%(levelname)s", '
            '"service": "%(name)s", "audit": %(message)s}'
        )
        audit_handler.setFormatter(audit_formatter)

        audit_logger = logging.getLogger("audit")
        audit_logger.setLevel(logging.INFO)
        audit_logger.addHandler(audit_handler)
        # Prevent propagation to root logger to avoid duplicate logs
        audit_logger.propagate = False

    def log_prediction(
        self,
        business_id: str,
        appointment_id: str,
        probability: float,
        risk_level: str,
        confidence: float,
        model_version: str,
        processing_time_ms: Optional[float] = None,
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
        source_ip: Optional[str] = None,
    ):
        """
        Log a prediction for HIPAA audit trail.

        IMPORTANT: Never log actual feature values or unhashed identifiers.
        """
        entry = {
            "action": AuditAction.PREDICTION_GENERATED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "business_id": business_id,  # Tenant ID is not PHI
            "appointment_id_hash": hash_identifier(appointment_id),
            "user_id": user_id,
            "source_ip": source_ip,
            "outcome": {
                "probability": round(probability, 3),
                "risk_level": risk_level,
                "confidence": round(confidence, 3),
            },
            "model_version": model_version,
            "processing_time_ms": round(processing_time_ms, 1) if processing_time_ms else None,
        }

        logger.info(json.dumps(entry))

    def log_batch_prediction(
        self,
        business_id: str,
        total_predictions: int,
        risk_level_counts: Dict[str, int],
        processing_time_ms: float,
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
        source_ip: Optional[str] = None,
    ):
        """Log a batch prediction."""
        entry = {
            "action": AuditAction.BATCH_PREDICTION_GENERATED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "business_id": business_id,
            "user_id": user_id,
            "source_ip": source_ip,
            "outcome": {
                "total_predictions": total_predictions,
                "risk_level_counts": risk_level_counts,
            },
            "processing_time_ms": round(processing_time_ms, 1),
        }

        logger.info(json.dumps(entry))

    def log_prediction_failure(
        self,
        business_id: Optional[str],
        appointment_id: str,
        error_type: str,
        request_id: Optional[str] = None,
        source_ip: Optional[str] = None,
    ):
        """Log a failed prediction attempt."""
        entry = {
            "action": AuditAction.PREDICTION_FAILED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "business_id": business_id,
            "appointment_id_hash": hash_identifier(appointment_id),
            "source_ip": source_ip,
            "error_type": error_type,  # Don't include error message - may contain PHI
        }

        logger.info(json.dumps(entry))

    def log_unauthorized_access(
        self,
        reason: str,
        source_ip: Optional[str] = None,
        request_id: Optional[str] = None,
    ):
        """Log an unauthorized access attempt."""
        entry = {
            "action": AuditAction.UNAUTHORIZED_ACCESS.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "source_ip": source_ip,
            "reason": reason,
        }

        logger.warning(json.dumps(entry))

    def log_invalid_tenant_access(
        self,
        claimed_business_id: str,
        authenticated_business_id: Optional[str],
        request_id: Optional[str] = None,
    ):
        """Log an attempt to access another tenant's data."""
        entry = {
            "action": AuditAction.INVALID_TENANT_ACCESS.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "claimed_business_id": claimed_business_id,
            "authenticated_business_id": authenticated_business_id,
        }

        logger.warning(json.dumps(entry))

    def log_model_loaded(
        self,
        model_name: str,
        model_version: str,
        is_mock: bool = False,
    ):
        """Log when a model is loaded."""
        entry = {
            "action": AuditAction.MODEL_LOADED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "model_name": model_name,
            "model_version": model_version,
            "is_mock": is_mock,
        }

        logger.info(json.dumps(entry))

    def log_model_reload_requested(
        self,
        model_name: str,
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ):
        """Log when a model reload is requested."""
        entry = {
            "action": AuditAction.MODEL_RELOAD_REQUESTED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "model_name": model_name,
            "user_id": user_id,
        }

        logger.info(json.dumps(entry))


# Global audit logger instance
audit_logger = AuditLogger()
