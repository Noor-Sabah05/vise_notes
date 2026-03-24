#!/bin/bash
# ViseNotes Integrated Backend Startup Script (macOS/Linux)
# Runs with proper timeout configuration for 15+ minute transcription support

echo ""
echo "========================================"
echo "  ViseNotes Integrated Backend"
echo "========================================"
echo ""
echo "Starting server with timeout configuration..."
echo "- Disable keep-alive timeout (long requests support)"
echo "- Process can take 15+ minutes for transcription"
echo ""

# Activate virtual environment
if [ -f venv/bin/activate ]; then
    source venv/bin/activate
    echo "✓ Virtual environment activated"
else
    echo "✗ ERROR: Virtual environment not found"
    echo "   Run: python -m venv venv"
    echo "   Then: venv/bin/pip install -r requirements.txt"
    exit 1
fi

echo ""
echo "✓ Starting FastAPI server..."
echo "   Listening on http://0.0.0.0:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run uvicorn with proper timeout settings
# --timeout-keep-alive 0: Disable keep-alive timeout for long requests
# --timeout-notify 0: Allow graceful handling without premature disconnect
python -m uvicorn main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --reload \
    --timeout-keep-alive 0 \
    --timeout-notify 0

if [ $? -ne 0 ]; then
    echo ""
    echo "✗ Server failed to start"
    echo "   Make sure port 8000 is not in use"
    exit 1
fi
