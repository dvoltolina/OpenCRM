"""
Ollama API client for local LLM inference.
Supports both local development and cloud GPU deployment.

Agent AI-6: Python Sentiment Service (Ollama LLM)
"""
import json
import logging
import subprocess
from typing import Optional, List, Dict, Any
from datetime import datetime

import httpx

logger = logging.getLogger(__name__)


class OllamaClient:
    """
    Client for Ollama API.

    Works with:
    - Local Ollama installation
    - Ollama running in Docker
    - Cloud GPU with Ollama (RunPod, Lambda Labs)
    """

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        timeout: float = 60.0,
        default_model: str = "phi3:mini",
        deep_analysis_model: str = "llama3.1:8b",
    ):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.default_model = default_model
        self.deep_analysis_model = deep_analysis_model
        self._client = httpx.AsyncClient(timeout=timeout)

        # Stats
        self._total_requests = 0
        self._total_latency_ms = 0.0

    async def check_connection(self) -> bool:
        """Check if Ollama is reachable."""
        try:
            response = await self._client.get(f"{self.base_url}/api/tags")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Ollama connection check failed: {e}")
            return False

    async def list_models(self) -> List[str]:
        """List available models."""
        try:
            response = await self._client.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                data = response.json()
                return [m["name"] for m in data.get("models", [])]
            return []
        except Exception as e:
            logger.error(f"Failed to list models: {e}")
            return []

    async def ensure_model_loaded(self, model: str) -> bool:
        """Ensure a model is loaded and ready."""
        models = await self.list_models()
        if model not in models:
            logger.warning(f"Model {model} not found. Available: {models}")
            return False
        return True

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        model: Optional[str] = None,
        temperature: float = 0.1,  # Low temp for consistent JSON
        max_tokens: int = 2000,
    ) -> Dict[str, Any]:
        """
        Generate a response from the LLM.

        Args:
            prompt: The user prompt
            system_prompt: Optional system prompt
            model: Model to use (defaults to self.default_model)
            temperature: Sampling temperature (lower = more deterministic)
            max_tokens: Maximum tokens to generate

        Returns:
            Dict with 'response', 'model', 'processing_time_ms', etc.
        """
        model = model or self.default_model
        start_time = datetime.now()

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        try:
            response = await self._client.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": temperature,
                        "num_predict": max_tokens,
                    },
                    "format": "json",  # Request JSON output
                },
            )

            if response.status_code != 200:
                raise Exception(
                    f"Ollama returned {response.status_code}: {response.text}"
                )

            result = response.json()

            # Track stats
            elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
            self._total_requests += 1
            self._total_latency_ms += elapsed_ms

            return {
                "response": result.get("message", {}).get("content", ""),
                "model": model,
                "processing_time_ms": elapsed_ms,
                "eval_count": result.get("eval_count", 0),
                "eval_duration": result.get("eval_duration", 0),
            }

        except httpx.TimeoutException:
            logger.error(f"Ollama request timed out after {self.timeout}s")
            raise
        except Exception as e:
            logger.error(f"Ollama generation failed: {e}")
            raise

    async def analyze_sentiment(
        self,
        text: str,
        source: str,
        system_prompt: str,
        analysis_prompt: str,
        deep: bool = False,
    ) -> Dict[str, Any]:
        """
        Analyze sentiment of text using LLM.

        Returns parsed JSON response from the model.
        """
        model = self.deep_analysis_model if deep else self.default_model

        result = await self.generate(
            prompt=analysis_prompt,
            system_prompt=system_prompt,
            model=model,
            temperature=0.1,
        )

        # Parse JSON response
        try:
            parsed = json.loads(result["response"])
            parsed["_meta"] = {
                "model": result["model"],
                "processing_time_ms": result["processing_time_ms"],
            }
            return parsed
        except json.JSONDecodeError as e:
            logger.error(
                f"Failed to parse LLM response as JSON: {result['response'][:500]}"
            )
            # Return a safe default
            return {
                "sentiment_score": 0.0,
                "confidence": 0.0,
                "risk_indicators": [],
                "vip_indicators": [],
                "summary": "Analysis failed - could not parse response",
                "_meta": {
                    "model": result["model"],
                    "processing_time_ms": result["processing_time_ms"],
                    "parse_error": str(e),
                },
            }

    @property
    def stats(self) -> Dict[str, Any]:
        """Get client statistics."""
        return {
            "total_requests": self._total_requests,
            "avg_latency_ms": (
                self._total_latency_ms / self._total_requests
                if self._total_requests > 0
                else 0
            ),
        }

    async def close(self):
        """Close the HTTP client."""
        await self._client.aclose()


def get_gpu_info() -> Dict[str, Any]:
    """Get GPU information if available."""
    try:
        result = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=memory.used,memory.total",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            used, total = result.stdout.strip().split(", ")
            return {
                "available": True,
                "memory_used_mb": float(used),
                "memory_total_mb": float(total),
            }
    except Exception:
        pass
    return {"available": False}
