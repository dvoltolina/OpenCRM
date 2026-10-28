"""
Lightweight risk/VIP keyword matcher to ensure indicators are produced even
when provider responses do not include them (e.g., VADER fallback).
"""
from datetime import datetime
from typing import List, Tuple

from .schemas import IndicatorSeverity, IndicatorType, RiskIndicator, SentimentSource


class RiskKeywordMatcher:
    """Detect simple risk/VIP indicators using curated keyword lists."""

    def __init__(self):
        self.risk_rules = [
            (
                ["cancel", "refund", "reschedule", "rescheduling", "late fee"],
                "cancellation_risk",
                IndicatorSeverity.MEDIUM,
            ),
            (
                ["angry", "upset", "frustrated", "complain", "complaint", "disappointed"],
                "dissatisfaction",
                IndicatorSeverity.HIGH,
            ),
            (
                ["lawsuit", "sue", "legal", "violation", "unsafe", "malpractice"],
                "legal_risk",
                IndicatorSeverity.CRITICAL,
            ),
        ]

        self.vip_rules = [
            (["thank you", "thanks", "appreciate", "grateful"], "gratitude"),
            (["amazing", "excellent", "outstanding", "great service"], "praise"),
            (["recommend", "refer", "loyal", "vip"], "loyalty"),
        ]

    def match(
        self,
        text: str,
        source: SentimentSource,
        source_document_id: str | None,
    ) -> Tuple[List[RiskIndicator], List[RiskIndicator]]:
        """Return (risk_indicators, vip_indicators) based on keyword matches."""
        lower = (text or "").lower()
        risk_indicators: List[RiskIndicator] = []
        vip_indicators: List[RiskIndicator] = []

        for keywords, category, severity in self.risk_rules:
            for keyword in keywords:
                if keyword in lower:
                    risk_indicators.append(
                        self._make_indicator(
                            indicator_type=IndicatorType.RISK,
                            category=category,
                            description=f"Detected '{keyword}'",
                            severity=severity,
                            trigger_text=keyword,
                            source=source,
                            source_document_id=source_document_id,
                        )
                    )
                    break

        for keywords, category in self.vip_rules:
            for keyword in keywords:
                if keyword in lower:
                    vip_indicators.append(
                        self._make_indicator(
                            indicator_type=IndicatorType.VIP,
                            category=category,
                            description=f"Detected '{keyword}'",
                            severity=IndicatorSeverity.LOW,
                            trigger_text=keyword,
                            source=source,
                            source_document_id=source_document_id,
                        )
                    )
                    break

        return risk_indicators, vip_indicators

    def _make_indicator(
        self,
        indicator_type: IndicatorType,
        category: str,
        description: str,
        severity: IndicatorSeverity,
        trigger_text: str,
        source: SentimentSource,
        source_document_id: str | None,
    ) -> RiskIndicator:
        return RiskIndicator(
            id=f"kw_{indicator_type.value}_{category}",
            type=indicator_type,
            severity=severity,
            category=category,
            description=description,
            confidence=0.65,
            source=source,
            source_document_id=source_document_id,
            trigger_text=trigger_text,
            detected_at=datetime.utcnow(),
            suggested_action=None,
        )
