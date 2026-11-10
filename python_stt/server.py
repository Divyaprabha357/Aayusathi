"""
AAYUSATHI Doctor Portal — Local Python STT Server
FastAPI HTTP Microservice exposing Whisper Speech-to-Text on 127.0.0.1:8765.
Communicates strictly over localhost with the Flutter Doctor Portal desktop client.
Zero raw audio data is persisted to disk or cloud storage.
"""

import os
import sys
import base64
import logging
from typing import Optional

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import numpy as np

from stt_engine import WhisperSTTEngine


# ============================================================
# Configure logging
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s"
)

logger = logging.getLogger("AayusathiSTTServer")


# ============================================================
# FastAPI App initialization
# ============================================================

app = FastAPI(
    title="AAYUSATHI Doctor Portal — Local STT Service",
    description="Local Whisper-based Speech-to-Text HTTP Microservice for Doctor Consultation Fields",
    version="1.0.0"
)


# ============================================================
# CORS Middleware
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# ============================================================
# Shared singleton STT engine
# ============================================================

DEFAULT_MODEL = os.getenv(
    "AAYUSATHI_WHISPER_MODEL",
    "base"
)

engine = WhisperSTTEngine(
    model_size=DEFAULT_MODEL
)


# ============================================================
# Request & Response Schemas
# ============================================================

class StartRecordingRequest(BaseModel):

    field_id: str = Field(
        ...,
        description="Target consultation field identifier, e.g. 'chiefComplaint'"
    )

    # AUTO = Whisper automatically detects English / Hindi / Marathi
    language: Optional[str] = Field(
        "auto",
        description="Spoken language code ('en', 'hi', 'mr') or 'auto'"
    )


class StopRecordingRequest(BaseModel):

    field_id: Optional[str] = Field(
        None,
        description="Optional target field identifier to confirm matching session"
    )


class TranscribeAudioRequest(BaseModel):

    audio_base64: str = Field(
        ...,
        description="Base64 encoded raw 16kHz mono float32 or int16 PCM audio"
    )

    dtype: Optional[str] = Field(
        "float32",
        description="Audio sample format ('float32' or 'int16')"
    )

    sample_rate: Optional[int] = Field(
        16000,
        description="Sample rate in Hz"
    )

    # AUTO = automatic language detection
    language: Optional[str] = Field(
        "auto",
        description="Target language code ('en', 'hi', 'mr') or 'auto'"
    )


# ============================================================
# Startup
# ============================================================

@app.on_event("startup")
async def startup_event():

    logger.info(
        "Starting AAYUSATHI Local Python STT Service..."
    )

    logger.info(
        f"Binding: 127.0.0.1:8765 | "
        f"Whisper Model: {engine.model_size}"
    )

    mic_status = (
        "READY"
        if engine.is_microphone_available()
        else "UNAVAILABLE"
    )

    logger.info(
        f"Microphone Hardware Status: {mic_status}"
    )

    # Initialize and warm up the Whisper model during service startup
    # so first transcription does not incur cold-start latency.
    logger.info(
        "Preloading and warming up Whisper model during service startup..."
    )

    try:
        loaded = engine.load_model()
        if loaded:
            logger.info(
                f"Whisper model '{engine.model_size}' preloaded successfully."
            )
            try:
                # 1 second of silence at 16kHz to prime CTranslate2 compute graphs
                dummy_audio = np.zeros(16000, dtype=np.float32)
                _ = engine.transcribe_array(dummy_audio, language="en")
                logger.info(
                    "Whisper model warmup completed successfully and ready for instant transcription."
                )
            except Exception as w_err:
                logger.warning(
                    f"Whisper warmup warning (non-fatal): {w_err}"
                )
        else:
            logger.warning(
                "Whisper model could not be preloaded at startup; will load on first request."
            )
    except Exception as e:
        logger.warning(
            f"Whisper preload error during startup (non-fatal): {e}"
        )


# ============================================================
# Shutdown
# ============================================================

@app.on_event("shutdown")
async def shutdown_event():

    logger.info(
        "Shutting down AAYUSATHI Local Python STT Service..."
    )

    engine.cancel_recording()


# ============================================================
# Health Check
# ============================================================

@app.get("/health")
def health_check():

    """
    Health check endpoint for Flutter Doctor Portal initialization.

    Returns engine state, model configuration,
    and microphone status.
    """

    return {
        "status": "ok",
        "service": "aayusathi-python-stt",
        "version": "1.0.0",
        "engine": "faster-whisper",
        "model": engine.model_size,
        "is_model_loaded": engine.is_engine_ready(),
        "is_recording": engine.is_recording,
        "is_processing": engine.is_processing,
        "microphone_available": engine.is_microphone_available(),

        # Supported languages
        "supported_languages": [
            "en",
            "hi",
            "mr",
            "auto"
        ]
    }


# ============================================================
# Status
# ============================================================

@app.get("/status")
def get_status():

    """
    Returns live recording status,
    active consultation field,
    and elapsed duration.
    """

    state_str = "idle"

    if engine.is_recording:
        state_str = "listening"

    elif engine.is_processing:
        state_str = "processing"

    return {
        "state": state_str,
        "active_field": engine.active_field,
        "recording_duration_seconds": round(
            engine.recording_duration,
            2
        ),
        "is_recording": engine.is_recording,
        "is_processing": engine.is_processing,
    }


# ============================================================
# Start Recording
# ============================================================

@app.post("/start")
def start_recording(req: StartRecordingRequest):

    """
    Begins capturing microphone audio for the specified
    consultation field.

    Microphone input is captured exclusively upon
    explicit doctor trigger.
    """

    try:

        # Convert empty/null language to automatic detection
        language = req.language or "auto"

        logger.info(
            f"Starting recording | "
            f"Field: {req.field_id} | "
            f"Language: {language}"
        )

        res = engine.start_recording(
            field_id=req.field_id,
            language=language
        )

        return res

    except RuntimeError as e:

        logger.error(
            f"Start recording failed: {e}"
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

    except Exception as e:

        logger.error(
            f"Unexpected start recording error: {e}"
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to start recording: {e}"
        )


# ============================================================
# Stop Recording
# ============================================================

@app.post("/stop")
def stop_recording(
    req: Optional[StopRecordingRequest] = None
):

    """
    Stops microphone capture, transcribes the in-memory
    audio buffer via Whisper, and returns the finalized text.
    """

    try:

        logger.info(
            "Stopping recording and starting transcription..."
        )

        res = engine.stop_recording()

        return res

    except Exception as e:

        logger.error(
            f"Stop recording failed: {e}"
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Transcription failed: {e}"
        )


# ============================================================
# Cancel Recording
# ============================================================

@app.post("/cancel")
def cancel_recording():

    """
    Aborts active recording session and discards
    buffered audio.
    """

    res = engine.cancel_recording()

    return res


# ============================================================
# Raw Audio Transcription
# ============================================================

@app.post("/transcribe_audio")
def transcribe_raw_audio(
    req: TranscribeAudioRequest
):

    """
    Offline/automated test endpoint.

    Accepts base64-encoded audio array,
    runs Whisper transcription in memory,
    and returns text without requiring physical
    microphone access.
    """

    try:

        raw_bytes = base64.b64decode(
            req.audio_base64
        )

        if req.dtype == "int16":

            int16_arr = np.frombuffer(
                raw_bytes,
                dtype=np.int16
            )

            audio_arr = (
                int16_arr.astype(np.float32)
                / 32768.0
            )

        else:

            audio_arr = np.frombuffer(
                raw_bytes,
                dtype=np.float32
            )

        # Automatic language detection
        language = req.language or "auto"

        logger.info(
            f"Transcribing raw audio | "
            f"Language: {language} | "
            f"Sample rate: {req.sample_rate}"
        )

        transcript = engine.transcribe_array(
            audio_arr,
            language=language
        )

        return {
            "status": "completed",
            "transcript": transcript,
            "sample_count": len(audio_arr),
            "language": language
        }

    except Exception as e:

        logger.error(
            f"Raw audio transcription error: {e}"
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ============================================================
# Run Server
# ============================================================

if __name__ == "__main__":

    import uvicorn

    port = int(
        os.getenv(
            "AAYUSATHI_STT_PORT",
            "8765"
        )
    )

    logger.info(
        f"Starting server on 127.0.0.1:{port}..."
    )

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=port,
        log_level="info"
    )