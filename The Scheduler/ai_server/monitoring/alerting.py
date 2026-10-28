"""
Alerting Service for Model Monitoring.

Sends alerts via Slack, email, and webhook when model performance
degrades or retraining is triggered.

Agent AI-17: Model Monitoring & Retraining Automation

HIPAA COMPLIANCE NOTES:
- No PHI is included in alerts
- Only aggregate metrics are reported
- All alerts are logged for audit trail
"""
import logging
import asyncio
import aiohttp
import json
from datetime import datetime
from typing import Optional, Dict, List, Any
from dataclasses import dataclass, field
from enum import Enum
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import aiosmtplib

logger = logging.getLogger(__name__)


class AlertSeverity(str, Enum):
    """Alert severity levels."""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class AlertChannel(str, Enum):
    """Supported alert channels."""
    SLACK = "slack"
    EMAIL = "email"
    WEBHOOK = "webhook"
    LOG = "log"


@dataclass
class AlertConfig:
    """Configuration for alert channels."""
    # Slack configuration
    slack_webhook_url: Optional[str] = None
    slack_channel: str = "#alerts"
    slack_mention_on_critical: str = "@channel"

    # Email configuration
    smtp_host: Optional[str] = None
    smtp_port: int = 587
    smtp_username: Optional[str] = None
    smtp_password: Optional[str] = None
    smtp_use_tls: bool = True
    email_from: str = "alerts@scheduler.example.com"
    email_to: List[str] = field(default_factory=list)

    # Webhook configuration
    webhook_url: Optional[str] = None
    webhook_headers: Dict[str, str] = field(default_factory=dict)

    # General settings
    enabled_channels: List[AlertChannel] = field(
        default_factory=lambda: [AlertChannel.LOG]
    )
    min_severity_for_email: AlertSeverity = AlertSeverity.ERROR
    dedupe_window_minutes: int = 60
    max_alerts_per_hour: int = 20


@dataclass
class Alert:
    """An alert to be sent."""
    severity: AlertSeverity
    title: str
    message: str
    business_id: Optional[str] = None
    model_version: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    metrics: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)
    alert_id: str = field(default_factory=lambda: datetime.utcnow().strftime("%Y%m%d%H%M%S%f"))


class AlertManager:
    """
    Manages sending alerts across multiple channels.

    Supports:
    - Slack webhooks
    - Email via SMTP
    - Generic webhooks
    - Local logging (always enabled)
    """

    def __init__(self, config: Optional[AlertConfig] = None):
        self.config = config or AlertConfig()
        self._recent_alerts: Dict[str, datetime] = {}
        self._alerts_this_hour: int = 0
        self._hour_start: datetime = datetime.utcnow()

    async def send_alert(
        self,
        severity: AlertSeverity,
        title: str,
        message: str,
        business_id: Optional[str] = None,
        model_version: Optional[str] = None,
        tags: Optional[List[str]] = None,
        metrics: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """
        Send an alert to configured channels.

        Returns True if alert was sent to at least one channel.
        """
        alert = Alert(
            severity=severity,
            title=title,
            message=message,
            business_id=business_id,
            model_version=model_version,
            tags=tags or [],
            metrics=metrics or {},
        )

        # Check rate limiting
        if not self._check_rate_limit():
            logger.warning(f"Alert rate limited: {alert.title}")
            return False

        # Check deduplication
        if self._is_duplicate(alert):
            logger.debug(f"Alert deduplicated: {alert.title}")
            return False

        # Always log
        self._log_alert(alert)

        # Send to configured channels
        results = []

        for channel in self.config.enabled_channels:
            if channel == AlertChannel.LOG:
                continue  # Already logged

            try:
                if channel == AlertChannel.SLACK and self.config.slack_webhook_url:
                    success = await self._send_slack(alert)
                    results.append(success)

                elif channel == AlertChannel.EMAIL and self.config.smtp_host:
                    if severity.value >= self.config.min_severity_for_email.value:
                        success = await self._send_email(alert)
                        results.append(success)

                elif channel == AlertChannel.WEBHOOK and self.config.webhook_url:
                    success = await self._send_webhook(alert)
                    results.append(success)

            except Exception as e:
                logger.error(f"Error sending alert via {channel}: {e}")
                results.append(False)

        # Track for deduplication
        self._record_alert(alert)

        return any(results) if results else True  # True if only logging

    def _check_rate_limit(self) -> bool:
        """Check if we're within rate limits."""
        now = datetime.utcnow()

        # Reset hourly counter
        if (now - self._hour_start).total_seconds() > 3600:
            self._hour_start = now
            self._alerts_this_hour = 0

        if self._alerts_this_hour >= self.config.max_alerts_per_hour:
            return False

        self._alerts_this_hour += 1
        return True

    def _is_duplicate(self, alert: Alert) -> bool:
        """Check if this alert is a duplicate of a recent one."""
        key = f"{alert.severity}:{alert.title}:{alert.business_id}"
        now = datetime.utcnow()

        if key in self._recent_alerts:
            last_sent = self._recent_alerts[key]
            minutes_ago = (now - last_sent).total_seconds() / 60
            if minutes_ago < self.config.dedupe_window_minutes:
                return True

        return False

    def _record_alert(self, alert: Alert):
        """Record alert for deduplication."""
        key = f"{alert.severity}:{alert.title}:{alert.business_id}"
        self._recent_alerts[key] = alert.created_at

        # Clean up old entries
        cutoff = datetime.utcnow()
        self._recent_alerts = {
            k: v for k, v in self._recent_alerts.items()
            if (cutoff - v).total_seconds() / 60 < self.config.dedupe_window_minutes * 2
        }

    def _log_alert(self, alert: Alert):
        """Log alert to application logs."""
        log_entry = {
            "alert_id": alert.alert_id,
            "severity": alert.severity.value,
            "title": alert.title,
            "message": alert.message,
            "business_id": alert.business_id,
            "model_version": alert.model_version,
            "tags": alert.tags,
            "metrics": alert.metrics,
            "created_at": alert.created_at.isoformat(),
        }

        if alert.severity == AlertSeverity.CRITICAL:
            logger.critical(f"ALERT: {json.dumps(log_entry)}")
        elif alert.severity == AlertSeverity.ERROR:
            logger.error(f"ALERT: {json.dumps(log_entry)}")
        elif alert.severity == AlertSeverity.WARNING:
            logger.warning(f"ALERT: {json.dumps(log_entry)}")
        else:
            logger.info(f"ALERT: {json.dumps(log_entry)}")

    async def _send_slack(self, alert: Alert) -> bool:
        """Send alert to Slack webhook."""
        if not self.config.slack_webhook_url:
            return False

        # Color based on severity
        color_map = {
            AlertSeverity.INFO: "#36a64f",      # Green
            AlertSeverity.WARNING: "#ffc107",   # Yellow
            AlertSeverity.ERROR: "#dc3545",     # Red
            AlertSeverity.CRITICAL: "#7b1fa2",  # Purple
        }

        # Build Slack message
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{self._get_emoji(alert.severity)} {alert.title}",
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": alert.message,
                }
            },
        ]

        # Add context
        context_elements = []
        if alert.business_id:
            context_elements.append({
                "type": "mrkdwn",
                "text": f"*Business:* {alert.business_id}",
            })
        if alert.model_version:
            context_elements.append({
                "type": "mrkdwn",
                "text": f"*Model:* {alert.model_version}",
            })
        if alert.tags:
            context_elements.append({
                "type": "mrkdwn",
                "text": f"*Tags:* {', '.join(alert.tags)}",
            })

        if context_elements:
            blocks.append({
                "type": "context",
                "elements": context_elements,
            })

        # Add metrics if present
        if alert.metrics:
            metrics_text = "\n".join(
                f"• *{k}:* {v}" for k, v in alert.metrics.items()
            )
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Metrics:*\n{metrics_text}",
                }
            })

        payload = {
            "channel": self.config.slack_channel,
            "attachments": [{
                "color": color_map.get(alert.severity, "#808080"),
                "blocks": blocks,
            }],
        }

        # Add mention for critical alerts
        if alert.severity == AlertSeverity.CRITICAL:
            payload["text"] = self.config.slack_mention_on_critical

        async with aiohttp.ClientSession() as session:
            async with session.post(
                self.config.slack_webhook_url,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=10),
            ) as response:
                success = response.status == 200
                if not success:
                    text = await response.text()
                    logger.error(f"Slack alert failed: {response.status} - {text}")
                return success

    async def _send_email(self, alert: Alert) -> bool:
        """Send alert via email."""
        if not self.config.smtp_host or not self.config.email_to:
            return False

        # Build email
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"[{alert.severity.value.upper()}] {alert.title}"
        msg["From"] = self.config.email_from
        msg["To"] = ", ".join(self.config.email_to)

        # Plain text version
        text_content = f"""
Model Monitoring Alert
======================
Severity: {alert.severity.value.upper()}
Title: {alert.title}

{alert.message}

Business ID: {alert.business_id or 'N/A'}
Model Version: {alert.model_version or 'N/A'}
Time: {alert.created_at.isoformat()}
        """

        if alert.metrics:
            text_content += "\nMetrics:\n"
            for k, v in alert.metrics.items():
                text_content += f"  - {k}: {v}\n"

        # HTML version
        html_content = f"""
        <html>
        <body>
            <h2 style="color: {self._get_severity_color(alert.severity)};">
                {alert.title}
            </h2>
            <p><strong>Severity:</strong> {alert.severity.value.upper()}</p>
            <p>{alert.message}</p>
            <hr>
            <p>
                <strong>Business ID:</strong> {alert.business_id or 'N/A'}<br>
                <strong>Model Version:</strong> {alert.model_version or 'N/A'}<br>
                <strong>Time:</strong> {alert.created_at.isoformat()}
            </p>
        """

        if alert.metrics:
            html_content += "<h3>Metrics</h3><ul>"
            for k, v in alert.metrics.items():
                html_content += f"<li><strong>{k}:</strong> {v}</li>"
            html_content += "</ul>"

        html_content += """
            <hr>
            <p style="color: gray; font-size: 12px;">
                This is an automated alert from The Scheduler AI monitoring system.
            </p>
        </body>
        </html>
        """

        msg.attach(MIMEText(text_content, "plain"))
        msg.attach(MIMEText(html_content, "html"))

        try:
            async with aiosmtplib.SMTP(
                hostname=self.config.smtp_host,
                port=self.config.smtp_port,
                use_tls=self.config.smtp_use_tls,
            ) as smtp:
                if self.config.smtp_username and self.config.smtp_password:
                    await smtp.login(
                        self.config.smtp_username,
                        self.config.smtp_password,
                    )
                await smtp.send_message(msg)
                return True

        except Exception as e:
            logger.error(f"Email alert failed: {e}")
            return False

    async def _send_webhook(self, alert: Alert) -> bool:
        """Send alert to generic webhook."""
        if not self.config.webhook_url:
            return False

        payload = {
            "alert_id": alert.alert_id,
            "severity": alert.severity.value,
            "title": alert.title,
            "message": alert.message,
            "business_id": alert.business_id,
            "model_version": alert.model_version,
            "tags": alert.tags,
            "metrics": alert.metrics,
            "created_at": alert.created_at.isoformat(),
        }

        headers = {
            "Content-Type": "application/json",
            **self.config.webhook_headers,
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(
                self.config.webhook_url,
                json=payload,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=10),
            ) as response:
                success = response.status >= 200 and response.status < 300
                if not success:
                    text = await response.text()
                    logger.error(f"Webhook alert failed: {response.status} - {text}")
                return success

    def _get_emoji(self, severity: AlertSeverity) -> str:
        """Get emoji for severity level."""
        emoji_map = {
            AlertSeverity.INFO: "ℹ️",
            AlertSeverity.WARNING: "⚠️",
            AlertSeverity.ERROR: "🚨",
            AlertSeverity.CRITICAL: "🔥",
        }
        return emoji_map.get(severity, "📢")

    def _get_severity_color(self, severity: AlertSeverity) -> str:
        """Get color for severity level."""
        color_map = {
            AlertSeverity.INFO: "#36a64f",
            AlertSeverity.WARNING: "#ffc107",
            AlertSeverity.ERROR: "#dc3545",
            AlertSeverity.CRITICAL: "#7b1fa2",
        }
        return color_map.get(severity, "#808080")


# Convenience functions for common alerts

async def send_performance_alert(
    alert_manager: AlertManager,
    business_id: str,
    model_version: str,
    auc_roc: float,
    threshold: float,
    calibration_error: float,
):
    """Send alert for degraded model performance."""
    severity = AlertSeverity.ERROR if auc_roc < threshold - 0.05 else AlertSeverity.WARNING

    await alert_manager.send_alert(
        severity=severity,
        title="Model Performance Degradation",
        message=(
            f"Model AUC-ROC ({auc_roc:.1%}) is below threshold ({threshold:.0%}).\n"
            f"Calibration error: {calibration_error:.1%}"
        ),
        business_id=business_id,
        model_version=model_version,
        tags=["performance", "auc"],
        metrics={
            "auc_roc": f"{auc_roc:.1%}",
            "threshold": f"{threshold:.0%}",
            "calibration_error": f"{calibration_error:.1%}",
        },
    )


async def send_drift_alert(
    alert_manager: AlertManager,
    business_id: str,
    model_version: str,
    drift_type: str,
    drift_score: float,
    drifted_features: List[str],
):
    """Send alert for detected drift."""
    severity = AlertSeverity.ERROR if drift_score > 5.0 else AlertSeverity.WARNING

    await alert_manager.send_alert(
        severity=severity,
        title=f"Model Drift Detected: {drift_type}",
        message=(
            f"Significant {drift_type} detected with score {drift_score:.2f}.\n"
            f"Affected features: {', '.join(drifted_features) if drifted_features else 'N/A'}"
        ),
        business_id=business_id,
        model_version=model_version,
        tags=["drift", drift_type.lower().replace(" ", "-")],
        metrics={
            "drift_score": f"{drift_score:.2f}",
            "drift_type": drift_type,
            "drifted_features": drifted_features,
        },
    )


async def send_retraining_alert(
    alert_manager: AlertManager,
    business_id: str,
    model_version: str,
    reasons: List[str],
    job_id: Optional[str],
):
    """Send alert for retraining trigger."""
    await alert_manager.send_alert(
        severity=AlertSeverity.INFO,
        title="Model Retraining Triggered",
        message=(
            f"Automatic retraining initiated for model {model_version}.\n"
            f"Reasons: {', '.join(reasons)}\n"
            f"Job ID: {job_id or 'N/A'}"
        ),
        business_id=business_id,
        model_version=model_version,
        tags=["retraining", "automation"],
        metrics={
            "reasons": reasons,
            "job_id": job_id,
        },
    )
