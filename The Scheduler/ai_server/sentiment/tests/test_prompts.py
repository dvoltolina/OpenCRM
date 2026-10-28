"""
Tests for LLM prompt templates.
Run with: pytest tests/test_prompts.py -v

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
import pytest
import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from sentiment.prompts import (
    format_source_for_prompt,
    build_analysis_prompt,
    build_batch_prompt,
    SENTIMENT_SYSTEM_PROMPT,
    SENTIMENT_ANALYSIS_PROMPT,
    DEEP_ANALYSIS_PROMPT,
    SOURCE_DESCRIPTIONS,
)


class TestSourceFormatting:
    """Tests for source formatting functions."""

    def test_format_source_sms_reply(self):
        """Test SMS reply source formatting."""
        result = format_source_for_prompt("smsReply")
        assert "SMS" in result
        assert "customer" in result.lower()

    def test_format_source_email_reply(self):
        """Test email reply source formatting."""
        result = format_source_for_prompt("emailReply")
        assert "Email" in result or "email" in result.lower()

    def test_format_source_cancellation(self):
        """Test cancellation reason source formatting."""
        result = format_source_for_prompt("cancellationReason")
        assert "cancell" in result.lower()

    def test_format_source_reschedule(self):
        """Test reschedule reason source formatting."""
        result = format_source_for_prompt("rescheduleReason")
        assert "reschedul" in result.lower()

    def test_format_source_feedback(self):
        """Test feedback text source formatting."""
        result = format_source_for_prompt("feedbackText")
        assert "feedback" in result.lower() or "review" in result.lower()

    def test_format_source_unknown(self):
        """Test unknown source returns original value."""
        result = format_source_for_prompt("unknownSource")
        assert result == "unknownSource"

    def test_all_sources_have_descriptions(self):
        """Test all expected sources have descriptions."""
        expected_sources = [
            "smsReply",
            "emailReply",
            "intakeFormText",
            "sessionNote",
            "cancellationReason",
            "rescheduleReason",
            "feedbackText",
            "staffNote",
        ]

        for source in expected_sources:
            assert source in SOURCE_DESCRIPTIONS
            assert len(SOURCE_DESCRIPTIONS[source]) > 0


class TestPromptBuilding:
    """Tests for prompt building functions."""

    def test_build_analysis_prompt_regular(self):
        """Test regular analysis prompt building."""
        prompt = build_analysis_prompt(
            text="Hello, this is a test",
            source="smsReply",
            deep=False,
        )

        assert "Hello, this is a test" in prompt
        assert "SMS" in prompt
        assert "sentiment_score" in prompt
        assert "risk_indicators" in prompt
        assert "vip_indicators" in prompt

    def test_build_analysis_prompt_deep(self):
        """Test deep analysis prompt building."""
        prompt = build_analysis_prompt(
            text="Hello, this is a test",
            source="smsReply",
            deep=True,
        )

        assert "Hello, this is a test" in prompt
        # Deep analysis has additional fields
        assert "emotional_undertones" in prompt
        assert "healthcare" in prompt.lower() or "wellness" in prompt.lower()

    def test_build_batch_prompt(self):
        """Test batch prompt building."""
        texts = [
            {"text_id": "1", "source": "smsReply", "text": "First message"},
            {"text_id": "2", "source": "emailReply", "text": "Second message"},
        ]

        prompt = build_batch_prompt(texts)

        assert "2" in prompt  # count
        assert "First message" in prompt
        assert "Second message" in prompt
        assert "Text ID: 1" in prompt
        assert "Text ID: 2" in prompt

    def test_prompt_json_structure(self):
        """Test that prompts request valid JSON structure."""
        prompt = build_analysis_prompt(
            text="Test",
            source="smsReply",
            deep=False,
        )

        # Should contain JSON structure markers
        assert "{" in prompt
        assert "}" in prompt
        assert "sentiment_score" in prompt
        assert "confidence" in prompt


class TestSystemPrompt:
    """Tests for system prompt."""

    def test_system_prompt_exists(self):
        """Test system prompt is defined."""
        assert len(SENTIMENT_SYSTEM_PROMPT) > 0

    def test_system_prompt_mentions_json(self):
        """Test system prompt requires JSON output."""
        assert "JSON" in SENTIMENT_SYSTEM_PROMPT

    def test_system_prompt_explains_scoring(self):
        """Test system prompt explains sentiment scoring."""
        assert "-1" in SENTIMENT_SYSTEM_PROMPT or "negative" in SENTIMENT_SYSTEM_PROMPT
        assert "1" in SENTIMENT_SYSTEM_PROMPT or "positive" in SENTIMENT_SYSTEM_PROMPT


class TestPromptCategories:
    """Tests for category definitions in prompts."""

    def test_risk_categories_defined(self):
        """Test risk categories are defined in prompts."""
        expected_risk_categories = [
            "frustration",
            "dissatisfaction",
            "price_complaint",
            "service_complaint",
            "scheduling_issue",
            "churn_intent",
        ]

        for category in expected_risk_categories:
            assert category in SENTIMENT_ANALYSIS_PROMPT

    def test_vip_categories_defined(self):
        """Test VIP categories are defined in prompts."""
        expected_vip_categories = [
            "loyalty",
            "referral_intent",
            "positive_review",
            "gratitude",
        ]

        for category in expected_vip_categories:
            assert category in SENTIMENT_ANALYSIS_PROMPT
