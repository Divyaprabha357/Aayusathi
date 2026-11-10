# AAYUSATHI — Arduino Hardware Integration Guide

## 1. Hardware Architecture Overview
The AAYUSATHI kiosk terminal interfaces directly with an **Arduino Uno (ATmega328P)** via USB Serial to collect three essential vital signs:
1. **Blood Oxygen (SpO₂ %)** — via MAX30100 / MAX30102 optical sensor
2. **Heart Rate (BPM)** — via MAX30100 / MAX30102 photoplethysmography
3. **Body Temperature (°C)** — via LM35 / DS18B20 analog or digital sensor

> **Note on Blood Pressure:** Blood pressure monitoring is completely removed from the AAYUSATHI kiosk architecture due to sensor unavailability. No BP sensors, cards, or simulated BP data are present.

---

## 2. Arduino IDE Setup & Board Flashing
1. **Board Selection:** In Arduino IDE, select **Tools > Board > Arduino AVR Boards > Arduino Uno**.
2. **Port Selection:** Select **Tools > Port > COM7** (or whichever COM port your Windows Device Manager assigns to the Arduino).
3. **Sketch Location:** Open `arduino/aayusathi_vitals/aayusathi_vitals.ino`.
4. **Baud Rate:** Communication is fixed at **9600 baud** (`8-N-1`).
5. **Upload:** Click the **Upload** button (`Ctrl+U`).

---

## 3. Communication Protocol (Software Trigger)
A bidirectional command-telemetry protocol is used:

### A. Host -> Arduino Commands
| Command | Terminators | Action |
| :--- | :--- | :--- |
| `START\n` | `\n` or `\r\n` | Starts continuous or sampled vital acquisition. |
| `STOP\n` | `\n` or `\r\n` | Halts acquisition stream and parks sensors. |

### B. Arduino -> Host Telemetry
The firmware transmits newline-delimited human-readable or compact telemetry parsed by `ArduinoSerialParser`:
```text
VITAL RESULTS
Heart Rate : 74 BPM
SpO2       : 98 %
Temperature: 36.6 C
```
Alternatively, compact format is supported:
```text
HR:74,SPO2:98,TEMP:36.6
```

---

## 4. Timeout & Deterministic Demo Fallback
- **Strict 15-Second Timeout:** When `TAKE VITALS` is pressed, a 15-second timer begins.
- **Valid Acquisition:** If complete readings arrive within 15 seconds, timeout is cancelled immediately and the values are marked `source: VitalSource.arduino`.
- **Hardware Failure / Timeout:** If the device is disconnected or 15 seconds elapse without valid sensor data:
  - If **Demo Mode** is enabled (`DemoReadingProvider.instance.isDemoModeEnabled = true`):
    - Values are provided deterministically:
      - **Attempt 1:** HR: 74 BPM, SpO2: 98%, Temp: 36.6 °C
      - **Attempt 2:** HR: 74 BPM, SpO2: 98%, Temp: 36.6 °C (exact identical match to Attempt 1)
      - **Attempt 3:** HR: 78 BPM, SpO2: 97%, Temp: 36.8 °C (different plausible set)
      - **Attempt 4+:** Deterministic cycle through plausible ranges.
    - All fallback readings are explicitly marked: `SIMULATED — HARDWARE TIMEOUT`.
    - A visible warning banner is displayed:
      `Hardware readings unavailable. Demo values are being displayed.`
  - If **Production Mode** is enabled (`isDemoModeEnabled = false`):
    - No fabricated values are generated. A hardware error state is presented.
- **Late Response Guard:** Any serial data arriving after the fallback is established is strictly discarded.

---

## 5. Circuit Wiring & Pinout (Sensor Shield V4.0 / Arduino Uno)
| Component | Module Pin | Arduino Uno / Shield Pin | Description |
| :--- | :--- | :--- | :--- |
| **MAX30102** | VCC | 3.3V or 5V (per module) | Optical sensor power |
| | GND | GND | Ground |
| | SDA | A4 (or dedicated SDA) | I2C Data |
| | SCL | A5 (or dedicated SCL) | I2C Clock |
| **DS18B20** | VCC | 5V | Temperature sensor power |
| | GND | GND | Ground |
| | DATA | Digital Pin 2 | 1-Wire Data (4.7k pullup to 5V) |
| **Buzzer** | POS (+) / S | Digital Pin 8 | Audio feedback signal |
| | GND (-) | GND | Ground |

### Audio Signal Cues
- **Boot:** Single chirp on board power-on.
- **Start Measurement:** Single 1200 Hz alert beep when `TAKE VITALS` is triggered from Kiosk.
- **Measurement Complete:** Two celebratory beeps (1500 Hz then 2000 Hz) when valid vitals are calculated.
- **Error / Disconnected:** Low 400 Hz warning tone if finger is not detected or sensor fails.

