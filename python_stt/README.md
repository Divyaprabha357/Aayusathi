# AAYUSATHI Doctor Portal — Local Python + Whisper STT Service

This directory contains the local, privacy-first **Speech-to-Text (STT) microservice** for the AAYUSATHI Doctor Portal. It converts spoken clinical consultations into text using [faster-whisper](https://github.com/SYSTRAN/faster-whisper) (CTranslate2) and captures microphone audio directly into memory using `sounddevice`.

---

## 1. Key Principles & Safety
- **Documentation Assistant Only**: STT strictly transcribes speech into text. It **never** generates medical diagnoses, prescribes medications, or approves clinical entries. The Doctor remains the sole final authority.
- **Zero Raw Audio Storage**: Audio is recorded in-memory via `sounddevice` @ 16 kHz mono float32, transcribed, and immediately discarded. No audio files are saved to disk, Firebase, or Supabase.
- **Localhost Bound**: Binds exclusively to `127.0.0.1:8765` without public internet exposure.

---

## 2. Prerequisites & Python Installation

### If Python is not yet installed:
Open PowerShell and install Python 3.11 using Windows Package Manager (`winget`):

```powershell
winget install Python.Python.3.11
```

*Alternatively, download and install Python 3.11 or 3.12 from [python.org](https://www.python.org/downloads/). Ensure **"Add python.exe to PATH"** is checked during installation.*

Verify the installation:
```powershell
python --version
# Expected: Python 3.11.x or 3.12.x
```

---

## 3. Setup Virtual Environment & Install Dependencies

From the project root, navigate to `python_stt/`:

```powershell
cd c:\DEVELOPEMENT\aayusathi\python_stt
```

Create a dedicated virtual environment:
```powershell
python -m venv .venv
```

Activate the virtual environment:
```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Or Command Prompt (cmd)
.\.venv\Scripts\activate.bat
```

Install required packages:
```powershell
pip install -r requirements.txt
```

---

## 4. Starting the Service

Run the server:
```powershell
python server.py
```

The service will start on:
```
http://127.0.0.1:8765
```

You should see startup logs:
```
[INFO] Starting AAYUSATHI Local Python STT Service...
[INFO] Binding: 127.0.0.1:8765 | Whisper Model: base
[INFO] Microphone Hardware Status: READY
[INFO] Uvicorn running on http://127.0.0.1:8765
```

---

## 5. API Endpoints Reference

All endpoints are bound strictly to `127.0.0.1:8765`:

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Service health, model status, and microphone readiness. |
| `GET` | `/status` | Active field, recording duration, and current state. |
| `POST` | `/start` | Starts microphone capture for a target field (e.g. `{"field_id": "chiefComplaint", "language": "en"}`). |
| `POST` | `/stop` | Stops recording, runs Whisper transcription, and returns text payload. |
| `POST` | `/cancel` | Aborts recording and purges in-memory buffer without transcribing. |
| `POST` | `/transcribe_audio` | Automated/offline test endpoint accepting base64 audio. |

---

## 6. Model Selection & Tuning

By default, the engine uses the `base` model (`faster-whisper`), which provides a balanced speed-to-accuracy trade-off for a student Windows laptop CPU:

| Model | Size | RAM/VRAM | Approx. CPU Latency | Languages Supported |
| :--- | :---: | :---: | :---: | :--- |
| `tiny` | ~39 MB | ~150 MB | ~150 ms | English, Hindi, Marathi, 90+ |
| `base` *(Default)* | ~75 MB | ~250 MB | ~350 ms | English, Hindi, Marathi, 90+ |
| `small` | ~240 MB | ~600 MB | ~900 ms | English, Hindi, Marathi, 90+ |

To switch models, set the environment variable before starting:
```powershell
$env:AAYUSATHI_WHISPER_MODEL = "small"
python server.py
```

---

## 7. Troubleshooting

- **Microphone unavailable / permission error**:
  - Open Windows Settings $\rightarrow$ **Privacy & security** $\rightarrow$ **Microphone**.
  - Ensure **"Microphone access"** and **"Let desktop apps access your microphone"** are enabled.
- **Port 8765 in use**:
  - Change the port by setting:
    ```powershell
    $env:AAYUSATHI_STT_PORT = "8766"
    python server.py
    ```
- **Doctor Portal displays "Speech Service Offline"**:
  - Ensure `python server.py` is running in an active terminal window.
  - Test health check in your browser: [http://127.0.0.1:8765/health](http://127.0.0.1:8765/health).
  - You can continue to type consultation notes manually into the Doctor Portal at any time without interruption.
