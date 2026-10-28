"""
HIPAA-compliant audit logging for sentiment analysis service.

All AI predictions and automated actions MUST be logged here.
Logs are structured for compliance reporting and incident investigation.

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
import logging
import json
import hashlib
from datetime import datetime
from typing import Optional, Dict, Any
from enum import Enum

logger = logging.getLogger("audit")


class AuditAction(str, Enum):
    """Auditable actions in the sentiment service."""
    SENTIMENT_ANALYZED = "ai_sentiment_analyzed"
    BATCH_SENTIMENT_ANALYZED = "ai_batch_sentiment_analyzed"
    ANALYSIS_FAILED = "ai_sentiment_analysis_failed"
    UNAUTHORIZED_ACCESS = "unauthorized_access_attempt"
    INVALID_TENANT_ACCESS = "invalid_tenant_access_attempt"


def hash_identifier(identifier: str) -> str:
    """
    Hash an identifier for logging purposes.
    PHI identifiers should be hashed, not logged in plain text.
    """
    return hashlib.sha256(identifier.encode()).hexdigest()[:16]


def sanitize_for_log(text: Optional[str], max_length: int = 50) -> str:
    """
    Sanitize text for logging - removes PHI by truncating and hashing.
    Never log actual client text content.
    """
    if not text:
        return "[empty]"
    # Return length indicator only, not content
    return f"[text_length={len(text)}]"


class AuditLogger:
    """
    HIPAA-compliant audit logger.

    All entries include:
    - Timestamp (ISO 8601)
    - Action performed
    - Business ID (for tenant isolation verification)
    - Hashed client ID (PHI protection)
    - Request metadata (no PHI)
    - Outcome (success/failure)
    """

    def __init__(self, service_name: str = "sentiment-service"):
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

    def log_sentiment_analysis(
        self,
        business_id: str,
        client_id: str,
        source: str,
        endpoint: str,
        status_code: int,
        provider: Optional[str],
        sentiment_score: float,
        confidence: float,
        risk_indicator_count: int,
        vip_indicator_count: int,
        model_version: str,
        processing_time_ms: int,
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ):
        """
        Log a sentiment analysis for HIPAA audit trail.

        IMPORTANT: Never log actual text content or unhashed identifiers.
        """
        entry = {
            "action": AuditAction.SENTIMENT_ANALYZED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "endpoint": endpoint,
            "status_code": status_code,
            "business_id": business_id,  # Tenant ID is not PHI
            "client_id_hash": hash_identifier(client_id),  # Hash the client ID
            "user_id": user_id,  # Staff member who triggered analysis
            "source_type": source,
            "provider": provider,
            "outcome": {
                "sentiment_score": round(sentiment_score, 3),
                "confidence": round(confidence, 3),
                "risk_indicator_count": risk_indicator_count,
                "vip_indicator_count": vip_indicator_count,
            },
            "model_version": model_version,
            "processing_time_ms": processing_time_ms,
        }

        logger.info(json.dumps(entry))

    def log_batch_analysis(
        self,
        business_id: str,
        endpoint: str,
        status_code: int,
        provider: Optional[str],
        total_texts: int,
        successful_count: int,
        error_count: int,
        processing_time_ms: float,
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ):
        """Log a batch sentiment analysis."""
        entry = {
            "action": AuditAction.BATCH_SENTIMENT_ANALYZED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "endpoint": endpoint,
            "status_code": status_code,
            "business_id": business_id,
            "user_id": user_id,
            "provider": provider,
            "outcome": {
                "total_texts": total_texts,
                "successful_count": successful_count,
                "error_count": error_count,
            },
            "processing_time_ms": round(processing_time_ms, 1),
        }

        logger.info(json.dumps(entry))

    def log_analysis_failure(
        self,
        business_id: str,
        client_id: str,
        error_type: str,
        endpoint: str,
        status_code: int,
        provider: Optional[str],
        request_id: Optional[str] = None,
    ):
        """Log a failed analysis attempt."""
        entry = {
            "action": AuditAction.ANALYSIS_FAILED.value,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "request_id": request_id,
            "endpoint": endpoint,
            "status_code": status_code,
            "business_id": business_id,
            "client_id_hash": hash_identifier(client_id),
            "error_type": error_type,  # Don't include error message - may contain PHI
            "provider": provider,
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


# Global audit logger instance
audit_logger = AuditLogger()
