#!/bin/bash
# =============================================================================
# RunPod Startup Script for Sentiment Analysis Service
# Agent AI-13: Docker & Cloud Deployment
# =============================================================================
#
# This script runs inside the RunPod container to:
# 1. Start Ollama server
# 2. Pull required models
# 3. Start the sentiment analysis service
#
# =============================================================================

set -euo pipefail

echo "========================================"
echo "Starting Scheduler Sentiment Service"
echo "========================================"

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
DEFAULT_MODEL="${SENTIMENT_DEFAULT_MODEL:-phi3:mini}"
DEEP_MODEL="${SENTIMENT_DEEP_ANALYSIS_MODEL:-llama3.1:8b}"

# =============================================================================
# Start Ollama
# =============================================================================

echo "[1/4] Starting Ollama server..."

# Start Ollama in background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! curl -s "http://localhost:${OLLAMA_PORT}/api/tags" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
        echo "ERROR: Ollama failed to start after ${MAX_RETRIES} attempts"
        exit 1
    fi
    echo "  Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

echo "Ollama is ready!"

# =============================================================================
# Pull Models
# =============================================================================

echo "[2/4] Pulling default model: ${DEFAULT_MODEL}..."
ollama pull "$DEFAULT_MODEL"
echo "Default model ready!"

# Pull deep model if different and VRAM is sufficient
if [[ "$DEEP_MODEL" != "$DEFAULT_MODEL" ]]; then
    echo "[3/4] Pulling deep analysis model: ${DEEP_MODEL}..."

    # Check available VRAM
    if command -v nvidia-smi &> /dev/null; then
        VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
        VRAM_GB=$((VRAM_MB / 1024))

        if [[ $VRAM_GB -ge 16 ]]; then
            ollama pull "$DEEP_MODEL"
            echo "Deep analysis model ready!"
        else
            echo "WARNING: Only ${VRAM_GB}GB VRAM available. Skipping ${DEEP_MODEL} (requires 16GB)."
            echo "Deep analysis will fall back to ${DEFAULT_MODEL}."
        fi
    else
        echo "WARNING: nvidia-smi not available. Attempting to pull ${DEEP_MODEL}..."
        ollama pull "$DEEP_MODEL" || echo "Failed to pull ${DEEP_MODEL}. Deep analysis will use ${DEFAULT_MODEL}."
    fi
else
    echo "[3/4] Deep model same as default, skipping..."
fi

# =============================================================================
# Pre-warm Models
# =============================================================================

echo "[4/4] Pre-warming models..."

# Send a test request to load model into VRAM
curl -s -X POST "http://localhost:${OLLAMA_PORT}/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"${DEFAULT_MODEL}\", \"prompt\": \"Hello\", \"stream\": false}" \
    > /dev/null 2>&1 || true

echo "Models pre-warmed!"

# =============================================================================
# Start Sentiment Service
# =============================================================================

echo ""
echo "========================================"
echo "Starting Sentiment Analysis API"
echo "========================================"

# Change to app directory
cd /app

# Start the sentiment service
exec python -m uvicorn main:app \
    --host "${SENTIMENT_HOST:-0.0.0.0}" \
    --port "${SENTIMENT_PORT:-8002}" \
    --workers 1 \
    --log-level "${SENTIMENT_LOG_LEVEL:-warning}"
