"""
LLM prompt templates for sentiment analysis.
Carefully engineered for consistent JSON output.

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""

# System prompt for sentiment analysis
SENTIMENT_SYSTEM_PROMPT = """You are an AI assistant specialized in analyzing customer communications for a scheduling/appointment business. Your job is to:

1. Determine the overall sentiment of the message (-1.0 = very negative, 0 = neutral, 1.0 = very positive)
2. Identify risk indicators that suggest the customer might leave (churn risk)
3. Identify VIP indicators that suggest the customer is highly satisfied or valuable
4. Provide actionable recommendations

You MUST respond with valid JSON only. No additional text or explanation."""


SENTIMENT_ANALYSIS_PROMPT = """Analyze the following customer communication:

SOURCE: {source}
TEXT: {text}

Respond with this exact JSON structure:
{{
  "sentiment_score": <float between -1.0 and 1.0>,
  "confidence": <float between 0.0 and 1.0>,
  "risk_indicators": [
    {{
      "category": "<category>",
      "description": "<what you detected>",
      "severity": "<critical|high|medium|low>",
      "trigger_text": "<relevant quote from text>",
      "suggested_action": "<what the business should do>"
    }}
  ],
  "vip_indicators": [
    {{
      "category": "<category>",
      "description": "<what you detected>",
      "trigger_text": "<relevant quote from text>"
    }}
  ],
  "summary": "<one sentence summary of the sentiment>",
  "recommended_action": "<primary recommended action or null>"
}}

Risk categories: frustration, dissatisfaction, price_complaint, service_complaint, scheduling_issue, communication_issue, health_concern, life_change, competitor_mention, churn_intent

VIP categories: loyalty, referral_intent, positive_review, gratitude, engagement, repeat_booking, premium_interest, advocate_signal

Be conservative with risk indicators - only flag genuine concerns, not neutral statements."""


DEEP_ANALYSIS_PROMPT = """Perform a deep sentiment analysis of the following customer communication. Consider context, tone, subtext, and emotional undertones:

SOURCE: {source}
TEXT: {text}

Additional context to consider:
- This is from a healthcare/wellness scheduling application
- Customers may be discussing sensitive health topics
- Look for subtle signs of dissatisfaction that might indicate churn risk
- Identify opportunities to strengthen the customer relationship

Respond with this exact JSON structure:
{{
  "sentiment_score": <float between -1.0 and 1.0>,
  "confidence": <float between 0.0 and 1.0>,
  "emotional_undertones": ["<detected emotions>"],
  "risk_indicators": [
    {{
      "category": "<category>",
      "description": "<detailed analysis>",
      "severity": "<critical|high|medium|low>",
      "trigger_text": "<relevant quote>",
      "suggested_action": "<specific recommendation>",
      "reasoning": "<why this is a concern>"
    }}
  ],
  "vip_indicators": [
    {{
      "category": "<category>",
      "description": "<detailed analysis>",
      "trigger_text": "<relevant quote>",
      "opportunity": "<how to leverage this>"
    }}
  ],
  "summary": "<comprehensive summary>",
  "recommended_action": "<primary action with priority>",
  "follow_up_suggestions": ["<additional recommendations>"]
}}"""


# Prompt for batch efficiency - analyze multiple texts in one call
BATCH_ANALYSIS_PROMPT = """Analyze the following {count} customer communications. For each one, determine sentiment and identify risk/VIP indicators.

{texts_formatted}

Respond with a JSON array containing one analysis object per text:
[
  {{
    "text_id": "<id from input>",
    "sentiment_score": <-1.0 to 1.0>,
    "confidence": <0.0 to 1.0>,
    "risk_indicators": [...],
    "vip_indicators": [...],
    "summary": "<one sentence>"
  }},
  ...
]

Be concise but accurate. Flag only genuine concerns."""


# Source descriptions for context in prompts
SOURCE_DESCRIPTIONS = {
    "smsReply": "SMS reply from customer",
    "emailReply": "Email reply from customer",
    "intakeFormText": "Free-text response from intake form",
    "sessionNote": "Provider's session notes about this client",
    "cancellationReason": "Reason given for cancelling appointment",
    "rescheduleReason": "Reason given for rescheduling appointment",
    "feedbackText": "Direct feedback/review from customer",
    "staffNote": "Staff notes about this client",
}


def format_source_for_prompt(source: str) -> str:
    """Convert source enum to human-readable format for prompts."""
    return SOURCE_DESCRIPTIONS.get(source, source)


def build_analysis_prompt(text: str, source: str, deep: bool = False) -> str:
    """Build the analysis prompt for a single text."""
    template = DEEP_ANALYSIS_PROMPT if deep else SENTIMENT_ANALYSIS_PROMPT
    return template.format(
        text=text,
        source=format_source_for_prompt(source)
    )


def build_batch_prompt(texts: list) -> str:
    """Build prompt for batch analysis."""
    formatted = "\n\n".join([
        f"[Text ID: {t['text_id']}]\nSOURCE: {format_source_for_prompt(t['source'])}\nTEXT: {t['text']}"
        for t in texts
    ])
    return BATCH_ANALYSIS_PROMPT.format(
        count=len(texts),
        texts_formatted=formatted
    )
