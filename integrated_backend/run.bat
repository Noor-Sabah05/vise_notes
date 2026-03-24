@echo off
REM ViseNotes Integrated Backend Startup Script (Windows)

echo.
echo ========================================
echo   ViseNotes Integrated Backend
echo ========================================
echo.

REM Activate virtual environment
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    echo ✓ Virtual environment activated
) else (
    echo ✗ ERROR: Virtual environment not found
    echo   Run: python -m venv venv
    echo   Then: venv\Scripts\pip install -r requirements.txt
    exit /b 1
)

echo.
echo ✓ Starting FastAPI server...
echo   Listening on http://0.0.0.0:8000
echo.
echo Press Ctrl+C to stop the server
echo.

REM Run uvicorn - Whisper handles long processes internally
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

if errorlevel 1 (
    echo.
    echo ✗ Server failed to start
    echo   Make sure port 8000 is not in use
    pause
    exit /b 1
)
