"""
AAYUSATHI Doctor Portal — Local Whisper Speech-to-Text Engine

Uses faster-whisper (CTranslate2) with in-memory audio capture
via sounddevice.

Supported languages:
    - English (en)
    - Hindi (hi)
    - Marathi (mr)
    - Automatic language detection (auto)

Strictly converts speech to text.
Does not diagnose or formulate clinical decisions.

Zero audio data is saved to disk or transmitted to external servers.
"""

import os
import sys
import time
import threading
import logging
from typing import Optional, Dict, Any, List

import numpy as np


# ============================================================
# Logging
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s"
)

logger = logging.getLogger("AayusathiWhisperEngine")


# ============================================================
# Optional Dependencies
# ============================================================

_faster_whisper_available = False
_sounddevice_available = False

try:
    from faster_whisper import WhisperModel

    _faster_whisper_available = True

except ImportError:
    WhisperModel = None


try:
    import sounddevice as sd

    _sounddevice_available = True

except ImportError:
    sd = None


# ============================================================
# Whisper STT Engine
# ============================================================

class WhisperSTTEngine:
    """
    Local Whisper Speech-to-Text Engine.

    Supports:
        English
        Hindi
        Marathi
        Automatic language detection

    Coordinates in-memory microphone capture
    and Whisper transcription.
    """

    # Whisper standard audio format
    SAMPLE_RATE = 16000
    CHANNELS = 1

    # Supported language codes
    SUPPORTED_LANGUAGES = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
        "auto": "Automatic Detection",
    }

    def __init__(
        self,
        model_size: str = "base",
        device: str = "auto",
        compute_type: str = "int8"
    ):

        self.model_size = os.getenv(
            "AAYUSATHI_WHISPER_MODEL",
            model_size
        )

        self.device = device
        self.compute_type = compute_type

        # Whisper model
        self.model: Optional[Any] = None

        self._model_loading = False
        self._model_load_lock = threading.Lock()

        # Recording state
        self._is_recording = False
        self._is_processing = False

        self._active_field_id: Optional[str] = None
        self._active_language: Optional[str] = None

        self._recording_start_time: float = 0.0

        # Last detected language
        self._last_detected_language: Optional[str] = None

        # In-memory audio buffer
        self._audio_chunks: List[np.ndarray] = []

        self._audio_stream = None
        self._lock = threading.Lock()

        logger.info(
            f"Initialized WhisperSTTEngine "
            f"(Target model: {self.model_size}, "
            f"compute: {self.compute_type})"
        )

    # ========================================================
    # Properties
    # ========================================================

    @property
    def is_recording(self) -> bool:
        return self._is_recording

    @property
    def is_processing(self) -> bool:
        return self._is_processing

    @property
    def active_field(self) -> Optional[str]:
        return self._active_field_id

    @property
    def last_detected_language(self) -> Optional[str]:
        return self._last_detected_language

    @property
    def recording_duration(self) -> float:

        if not self._is_recording:
            return 0.0

        return max(
            0.0,
            time.time() - self._recording_start_time
        )

    # ========================================================
    # Engine Status
    # ========================================================

    def is_engine_ready(self) -> bool:
        """
        Returns True when Whisper model is loaded.
        """

        return self.model is not None

    # ========================================================
    # Microphone Detection
    # ========================================================

    def is_microphone_available(self) -> bool:
        """
        Checks whether a valid microphone input device
        is available through sounddevice.
        """

        if not _sounddevice_available:
            return False

        try:

            devices = sd.query_devices()

            default_input = sd.default.device[0]

            if default_input is None or default_input < 0:

                return any(
                    d.get("max_input_channels", 0) > 0
                    for d in devices
                )

            return True

        except Exception as e:

            logger.warning(
                f"Microphone probe error: {e}"
            )

            return False

    # ========================================================
    # Model Loading
    # ========================================================

    def load_model(self) -> bool:
        """
        Loads the faster-whisper model into memory.

        The model is cached locally by faster-whisper/
        Hugging Face after the first download.
        """

        if not _faster_whisper_available:

            logger.error(
                "faster-whisper is not installed. "
                "Run: pip install faster-whisper"
            )

            return False

        with self._model_load_lock:

            if self.model is not None:
                return True

            if self._model_loading:
                logger.info(
                    "Whisper model is already loading..."
                )
                return False

            self._model_loading = True

            logger.info(
                f"Loading Whisper model "
                f"'{self.model_size}' "
                f"(device: {self.device}, "
                f"compute: {self.compute_type})..."
            )

            start_t = time.time()

            try:

                self.model = WhisperModel(
                    self.model_size,
                    device=self.device,
                    compute_type=self.compute_type,
                    download_root=os.getenv(
                        "AAYUSATHI_MODEL_DIR",
                        None
                    )
                )

                elapsed = time.time() - start_t

                logger.info(
                    f"Whisper model "
                    f"'{self.model_size}' "
                    f"loaded successfully "
                    f"in {elapsed:.2f}s."
                )

                return True

            except Exception as e:

                logger.error(
                    f"Failed to load Whisper model: {e}"
                )

                self.model = None

                return False

            finally:

                self._model_loading = False

    # ========================================================
    # Audio Callback
    # ========================================================

    def _audio_callback(
        self,
        indata,
        frames,
        time_info,
        status
    ):
        """
        Receives microphone audio chunks.

        Audio remains in memory only.
        """

        if status:

            logger.debug(
                f"Audio stream status: {status}"
            )

        with self._lock:

            if self._is_recording:

                self._audio_chunks.append(
                    indata.copy()
                )

    # ========================================================
    # Start Recording
    # ========================================================

    def start_recording(
        self,
        field_id: str,
        language: Optional[str] = None
    ) -> Dict[str, Any]:

        """
        Starts microphone capture.

        language:
            "en"   = English
            "hi"   = Hindi
            "mr"   = Marathi
            "auto" = Automatic detection
        """

        if not _sounddevice_available:

            raise RuntimeError(
                "Audio hardware library "
                "'sounddevice' is not available."
            )

        # Normalize language
        selected_language = (
            language.strip().lower()
            if language
            else "auto"
        )

        # Empty language = auto
        if not selected_language:
            selected_language = "auto"

        # Validate language
        if selected_language not in self.SUPPORTED_LANGUAGES:

            raise ValueError(
                f"Unsupported language '{selected_language}'. "
                f"Supported languages: "
                f"{', '.join(self.SUPPORTED_LANGUAGES.keys())}"
            )

        with self._lock:

            if self._is_recording:

                return {
                    "status": "already_recording",
                    "field_id": self._active_field_id,
                    "language": self._active_language or "auto",
                    "message": (
                        f"Already recording for field "
                        f"'{self._active_field_id}'."
                    )
                }

            if not self.is_microphone_available():

                raise RuntimeError(
                    "No microphone input device "
                    "found or accessible."
                )

            # Clear previous audio
            self._audio_chunks.clear()

            self._active_field_id = field_id
            self._active_language = selected_language

            self._last_detected_language = None

            self._recording_start_time = time.time()

            self._is_recording = True

            try:

                self._audio_stream = sd.InputStream(
                    samplerate=self.SAMPLE_RATE,
                    channels=self.CHANNELS,
                    dtype="float32",
                    callback=self._audio_callback
                )

                self._audio_stream.start()

                logger.info(
                    f"Started microphone capture "
                    f"for field '{field_id}' "
                    f"(language: {selected_language})"
                )

                return {
                    "status": "recording",
                    "field_id": field_id,
                    "language": selected_language,
                    "started_at": self._recording_start_time
                }

            except Exception as e:

                self._is_recording = False
                self._active_field_id = None
                self._active_language = None

                logger.error(
                    f"Failed to open microphone stream: {e}"
                )

                raise RuntimeError(
                    f"Microphone capture error: {e}"
                )

    # ========================================================
    # Stop Recording
    # ========================================================

    def stop_recording(self) -> Dict[str, Any]:

        """
        Stops microphone capture.

        Audio is transcribed from memory using Whisper.

        No audio file is written to disk.
        """

        with self._lock:

            if not self._is_recording:

                return {
                    "status": "idle",
                    "field_id": None,
                    "transcript": "",
                    "duration_ms": 0,
                    "language": "auto",
                    "message": (
                        "Engine was not actively recording."
                    )
                }

            self._is_recording = False
            self._is_processing = True

            field_id = (
                self._active_field_id
                or "unspecified"
            )

            language = (
                self._active_language
                or "auto"
            )

            duration = max(
                0.0,
                time.time()
                - self._recording_start_time
            )

            duration_ms = int(
                duration * 1000
            )

            # ----------------------------------------------
            # Stop microphone
            # ----------------------------------------------

            if self._audio_stream is not None:

                try:

                    self._audio_stream.stop()
                    self._audio_stream.close()

                except Exception as e:

                    logger.warning(
                        f"Error closing audio stream: {e}"
                    )

                finally:

                    self._audio_stream = None

            # ----------------------------------------------
            # Check audio
            # ----------------------------------------------

            if not self._audio_chunks:

                self._is_processing = False
                self._active_field_id = None
                self._active_language = None

                return {
                    "status": "completed",
                    "field_id": field_id,
                    "transcript": "",
                    "duration_ms": duration_ms,
                    "language": language,
                    "message": "No audio frames captured."
                }

            # ----------------------------------------------
            # Combine audio chunks
            # ----------------------------------------------

            audio_data = np.concatenate(
                self._audio_chunks,
                axis=0
            ).flatten()

            # Clear chunk references
            self._audio_chunks.clear()

        # ====================================================
        # Transcription
        # ====================================================

        try:

            logger.info(
                f"Processing {len(audio_data)} "
                f"audio samples ({duration:.2f}s) "
                f"for field '{field_id}' "
                f"using language '{language}'..."
            )

            transcript = self.transcribe_array(
                audio_data,
                language=language
            )

            detected_language = (
                self._last_detected_language
                or language
                or "auto"
            )

            logger.info(
                f"Transcription completed "
                f"for '{field_id}' | "
                f"Detected language: "
                f"{detected_language} | "
                f"Text: \"{transcript}\""
            )

            return {
                "status": "completed",
                "field_id": field_id,
                "transcript": transcript,
                "duration_ms": duration_ms,
                "language": detected_language
            }

        finally:

            # Make sure state is reset
            with self._lock:

                self._is_processing = False
                self._active_field_id = None
                self._active_language = None

    # ========================================================
    # Cancel Recording
    # ========================================================

    def cancel_recording(self) -> Dict[str, Any]:

        """
        Cancels active recording.

        Buffered audio is discarded.
        No transcription is performed.
        """

        with self._lock:

            field_id = self._active_field_id

            self._is_recording = False
            self._is_processing = False

            self._active_field_id = None
            self._active_language = None

            self._last_detected_language = None

            if self._audio_stream is not None:

                try:

                    self._audio_stream.stop()
                    self._audio_stream.close()

                except Exception:

                    pass

                finally:

                    self._audio_stream = None

            # Clear audio from memory
            self._audio_chunks.clear()

            logger.info(
                f"Cancelled recording session "
                f"for field '{field_id}'."
            )

            return {
                "status": "cancelled",
                "field_id": field_id
            }

    # ========================================================
    # Transcribe Audio Array
    # ========================================================

    def transcribe_array(
        self,
        audio_data: np.ndarray,
        language: Optional[str] = None
    ) -> str:

        """
        Transcribes a float32 16kHz mono numpy audio array.

        language:
            en   -> English
            hi   -> Hindi
            mr   -> Marathi
            auto -> Whisper automatically detects language

        When auto is selected, faster-whisper receives
        language=None, enabling automatic detection.
        """

        # ----------------------------------------------------
        # Validate audio
        # ----------------------------------------------------

        if audio_data is None:

            return ""

        if len(audio_data) < 1600:

            logger.warning(
                "Audio is too short for transcription."
            )

            return ""

        # ----------------------------------------------------
        # Normalize language
        # ----------------------------------------------------

        selected_language = (
            language.strip().lower()
            if language
            else "auto"
        )

        if not selected_language:

            selected_language = "auto"

        if selected_language not in self.SUPPORTED_LANGUAGES:

            raise ValueError(
                f"Unsupported language "
                f"'{selected_language}'. "
                f"Use en, hi, mr, or auto."
            )

        # ----------------------------------------------------
        # Ensure correct numpy format
        # ----------------------------------------------------

        audio_data = np.asarray(
            audio_data,
            dtype=np.float32
        )

        # Remove NaN / infinite values
        audio_data = np.nan_to_num(
            audio_data,
            nan=0.0,
            posinf=0.0,
            neginf=0.0
        )

        # ----------------------------------------------------
        # Ensure Whisper model is loaded
        # ----------------------------------------------------

        if self.model is None:

            logger.info(
                "Whisper model is not loaded. "
                "Loading now..."
            )

            loaded = self.load_model()

            if not loaded or self.model is None:

                raise RuntimeError(
                    "Whisper model failed to load. "
                    "Check faster-whisper installation."
                )

        # ----------------------------------------------------
        # Language selection
        # ----------------------------------------------------

        # Whisper expects:
        #
        # language="en" -> English
        # language="hi" -> Hindi
        # language="mr" -> Marathi
        #
        # language=None -> automatic detection

        whisper_language = (
            None
            if selected_language == "auto"
            else selected_language
        )

        logger.info(
            f"Whisper transcription started | "
            f"Requested language: {selected_language} | "
            f"Whisper language parameter: "
            f"{whisper_language or 'AUTO'}"
        )

        # ----------------------------------------------------
        # Transcribe
        # ----------------------------------------------------

        try:

            segments, info = self.model.transcribe(
                audio_data,

                # Automatic detection when auto
                language=whisper_language,

                # Beam search
                beam_size=5,

                # Remove silence
                vad_filter=True,

                vad_parameters=dict(
                    min_silence_duration_ms=500
                ),

                # IMPORTANT:
                # No English-specific initial prompt.
                # This prevents bias toward English.
                condition_on_previous_text=False
            )

            # ------------------------------------------------
            # Get detected language
            # ------------------------------------------------

            detected_language = getattr(
                info,
                "language",
                None
            )

            language_probability = getattr(
                info,
                "language_probability",
                None
            )

            if detected_language:

                self._last_detected_language = (
                    detected_language
                )

                if language_probability is not None:

                    logger.info(
                        f"Whisper detected language: "
                        f"{detected_language} "
                        f"(probability: "
                        f"{language_probability:.2f})"
                    )

                else:

                    logger.info(
                        f"Whisper detected language: "
                        f"{detected_language}"
                    )

            # ------------------------------------------------
            # Collect transcript segments
            # ------------------------------------------------

            texts = []

            for segment in segments:

                clean_seg = segment.text.strip()

                if clean_seg:

                    texts.append(clean_seg)

            final_text = " ".join(
                texts
            ).strip()

            logger.info(
                f"Final transcription: "
                f"\"{final_text}\""
            )

            return final_text

        except Exception as e:

            logger.error(
                f"Whisper transcription error: {e}"
            )

            raise RuntimeError(
                f"Whisper transcription failed: {e}"
            )
