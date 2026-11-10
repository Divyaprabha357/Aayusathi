#include <Wire.h>
#include <math.h>
#include <string.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <OneWire.h>
#include <DallasTemperature.h>

// ============================================================================
// AAYUSATHI VITALS MONITOR (KIOSK TERMINAL FIRMWARE)
// Hardware: Arduino UNO + Sensor Shield V4.0
// Sensors : MAX30102 (I2C SDA=A4, SCL=A5) + DS18B20 (Pin 2)
// Buzzer  : Active / Passive Piezo Buzzer on Digital Pin 8
// Port    : COM7 @ 9600 baud (Default AAYUSATHI Kiosk Configuration)
// ============================================================================

// Pin Configurations
#define TEMP_PIN 2     // DS18B20 1-Wire Digital Data Pin
#define BUZZER_PIN 8   // Piezo Buzzer Pin on Sensor Shield V4.0
#define LED_POWER 30   // MAX30102 LED Brightness (0-255)

// Optical Detection & Timing Parameters
#define FINGER_MIN 12000UL
#define SATURATION 250000UL
#define WAIT_MS 6000UL       // Wait up to 6s for finger placement
#define MEASURE_MS 8000UL    // Sample for 8s to complete within kiosk 15s timeout

MAX30105 maxSensor;
OneWire oneWire(TEMP_PIN);
DallasTemperature tempSensor(&oneWire);

// Global Sensor Status
bool maxReady = false;
bool tempOK = false;

char command[32];
byte commandPos = 0;

// ============================================================================
// AUDIO FEEDBACK (BUZZER HELPER FUNCTIONS)
// Compatible with both Active Buzzers and Passive Piezo Elements
// ============================================================================

void beep(int frequency, int durationMs) {
  pinMode(BUZZER_PIN, OUTPUT);
  tone(BUZZER_PIN, frequency, durationMs);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(durationMs);
  noTone(BUZZER_PIN);
  digitalWrite(BUZZER_PIN, LOW);
}

// Single tone when Kiosk triggers "TAKE VITALS"
void beepStart() {
  beep(1200, 250);
}

// Two celebratory beeps when measurement completes successfully
void beepFinish() {
  beep(1500, 150);
  delay(100);
  beep(2000, 300);
}

// Low warning tone if sensor disconnected or finger removed
void beepError() {
  beep(400, 400);
}

// ============================================================================
// OPTICAL SAMPLING (MAX30102)
// ============================================================================

bool getSample(uint32_t &ir, uint32_t &red) {
  unsigned long started = millis();

  while (!maxSensor.available()) {
    maxSensor.check();

    if (millis() - started > 1000UL) {
      return false;
    }
  }

  ir = maxSensor.getIR();
  red = maxSensor.getRed();

  maxSensor.nextSample();
  return true;
}

void configureMAX() {
  maxSensor.setup(
    LED_POWER,  // LED brightness
    1,          // Sample averaging
    2,          // Red + IR mode
    100,        // Sample rate
    411,        // Pulse width
    16384       // ADC range
  );

  maxSensor.setPulseAmplitudeRed(LED_POWER);
  maxSensor.setPulseAmplitudeIR(LED_POWER);
  maxSensor.setPulseAmplitudeGreen(0);

  maxSensor.clearFIFO();
}

// ============================================================================
// TEMPERATURE MEASUREMENT (DS18B20)
// ============================================================================

float readTemperature() {
  if (!tempOK) {
    return NAN;
  }

  tempSensor.requestTemperatures();
  float value = tempSensor.getTempCByIndex(0);

  if (value == DEVICE_DISCONNECTED_C || value < 20.0f || value > 50.0f) {
    return NAN;
  }

  return value;
}

// ============================================================================
// DISPLAY & TELEMETRY TRANSMISSION
// ============================================================================

void line() {
  Serial.println(F("------------------------------------"));
}

void printValue(float value, byte decimals) {
  if (isnan(value) || isinf(value)) {
    Serial.print(F("N/A"));
  } else {
    Serial.print(value, decimals);
  }
}

void showResults(
  float bpm,
  float oxygen,
  float temperature,
  byte beats,
  bool signalOK
) {
  Serial.println();
  line();
  Serial.println(F("        AAYUSATHI VITALS"));
  Serial.println(F("         TEST RESULTS"));
  line();

  // Primary telemetry lines parsed by AAYUSATHI Kiosk
  Serial.print(F("Heart Rate : "));
  printValue(bpm, 0);
  Serial.println(F(" BPM"));

  Serial.print(F("SpO2       : "));
  printValue(oxygen, 0);
  Serial.println(F(" %"));

  Serial.print(F("Temperature: "));
  printValue(temperature, 1);
  Serial.println(F(" C"));

  line();

  // Secondary metrics for diagnostic logging & reports
  Serial.print(F("BEATS FOUND  : "));
  Serial.println(beats);

  Serial.print(F("SIGNAL       : "));
  Serial.println(signalOK ? F("VALID") : F("UNSTABLE"));

  line();
  Serial.println(F("Send START or START_VITALS to repeat."));
  Serial.println();
}

// ============================================================================
// MAIN VITALS MEASUREMENT ROUTINE
// ============================================================================

void takeVitals() {
  // Beep immediately when Kiosk sends TAKE VITALS command
  beepStart();

  Serial.println();
  line();
  Serial.println(F("AAYUSATHI - STARTING MEASUREMENT"));
  line();

  // Measure body temperature first
  float temperature = readTemperature();

  float finalBPM = NAN;
  float oxygenEstimate = NAN;
  byte beats = 0;
  bool signalOK = false;

  Serial.print(F("Temperature: "));
  printValue(temperature, 1);
  Serial.println(F(" C"));

  if (!maxReady) {
    Serial.println(F("ERROR: MAX30102 not detected"));
    beepError();
    showResults(finalBPM, oxygenEstimate, temperature, beats, false);
    return;
  }

  configureMAX();

  Serial.println(F("Place finger on MAX30102"));
  Serial.println(F("Waiting for finger..."));

  uint32_t ir = 0;
  uint32_t red = 0;
  byte stable = 0;
  bool fingerFound = false;

  unsigned long waitStart = millis();

  while (millis() - waitStart < WAIT_MS) {
    if (!getSample(ir, red)) {
      break;
    }

    if (ir > FINGER_MIN && ir < SATURATION && red < SATURATION) {
      if (++stable >= 10) {
        fingerFound = true;
        break;
      }
    } else {
      stable = 0;
    }
  }

  if (!fingerFound) {
    Serial.println(F("ERROR: Finger not detected"));
    maxSensor.shutDown();
    beepError();
    showResults(finalBPM, oxygenEstimate, temperature, beats, false);
    return;
  }

  Serial.println(F("Finger detected. Measuring vitals..."));

  unsigned long startTime = millis();
  unsigned long lastBeat = 0;
  unsigned long lastPrint = 0;

  float bpmSum = 0;
  float bpmMin = 999;
  float bpmMax = 0;

  float dcIR = 0;
  float dcRed = 0;

  float irEnergy = 0;
  float redEnergy = 0;

  unsigned int sampleCount = 0;
  byte weakCount = 0;
  bool signalLost = false;

  // Measurement sampling loop
  while (millis() - startTime < MEASURE_MS) {
    if (!getSample(ir, red)) {
      signalLost = true;
      Serial.println(F("ERROR: Sensor timeout"));
      break;
    }

    if (ir >= SATURATION || red >= SATURATION) {
      signalLost = true;
      Serial.println(F("ERROR: Sensor saturated"));
      break;
    }

    if (ir < FINGER_MIN) {
      weakCount++;
      if (weakCount >= 10) {
        signalLost = true;
        Serial.println(F("ERROR: Finger removed"));
        break;
      }
    } else {
      weakCount = 0;
    }

    // Optical baseline calculation
    if (sampleCount == 0) {
      dcIR = (float)ir;
      dcRed = (float)red;
    }

    dcIR += 0.01f * ((float)ir - dcIR);
    dcRed += 0.01f * ((float)red - dcRed);

    float acIR = (float)ir - dcIR;
    float acRed = (float)red - dcRed;

    // Filter out initial contact motion
    if (millis() - startTime > 2000UL) {
      irEnergy += acIR * acIR;
      redEnergy += acRed * acRed;
    }

    sampleCount++;

    // Heart beat calculation
    if (checkForBeat(ir)) {
      unsigned long now = millis();
      if (lastBeat != 0) {
        unsigned long interval = now - lastBeat;
        if (interval >= 375 && interval <= 1500) {
          float bpm = 60000.0f / (float)interval;
          bpmSum += bpm;
          beats++;
          if (bpm < bpmMin) bpmMin = bpm;
          if (bpm > bpmMax) bpmMax = bpm;
        }
      }
      lastBeat = now;
    }

    // Progress updates every 2 seconds
    if (millis() - lastPrint >= 2000UL) {
      lastPrint = millis();
      Serial.print(F("Progress: "));
      Serial.print((millis() - startTime) / 1000);
      Serial.print(F("/8s | IR: "));
      Serial.print(ir);
      Serial.print(F(" | Beats: "));
      Serial.println(beats);
    }
  }

  maxSensor.shutDown();

  // Calculate final Heart Rate
  if (!signalLost && beats >= 2) {
    finalBPM = bpmSum / beats;
  }

  // Calculate SpO2 Estimation
  if (!signalLost && sampleCount > 80 && dcIR > 0 && dcRed > 0 && irEnergy > 0 && redEnergy > 0) {
    float ratio = (sqrt(redEnergy) / dcRed) / (sqrt(irEnergy) / dcIR);
    float estimate = 110.0f - 25.0f * ratio;

    if (!isnan(estimate) && !isinf(estimate) && estimate >= 70.0f && estimate <= 100.0f) {
      oxygenEstimate = estimate;
    }
  }

  signalOK = !signalLost && beats >= 2;

  // Beep when measurement finishes
  if (signalOK && !isnan(finalBPM) && !isnan(oxygenEstimate)) {
    beepFinish();
  } else {
    beepError();
  }

  showResults(finalBPM, oxygenEstimate, temperature, beats, signalOK);
}

// ============================================================================
// ARDUINO SETUP & INITIALIZATION
// ============================================================================

void setup() {
  // Serial communication at 9600 baud (Default AAYUSATHI COM7 rate)
  Serial.begin(9600);

  // Initialize Buzzer
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  Wire.begin();
  Wire.setClock(100000);

  // Initialize DS18B20 Temperature Sensor
  tempSensor.begin();
  tempOK = tempSensor.getDeviceCount() > 0;

  // Initialize MAX30102 Pulse Oximeter
  maxReady = maxSensor.begin(Wire, I2C_SPEED_STANDARD);
  if (maxReady) {
    configureMAX();
    maxSensor.shutDown();
  }

  // Startup chirp
  beep(1800, 100);

  Serial.println(F("===================================="));
  Serial.println(F("   AAYUSATHI VITAL MONITOR READY   "));
  Serial.println(F("   PORT: COM7 @ 9600 BAUD          "));
  Serial.println(F("===================================="));

  Serial.print(F("MAX30102 : "));
  Serial.println(maxReady ? F("CONNECTED") : F("NOT FOUND"));

  Serial.print(F("DS18B20  : "));
  Serial.println(tempOK ? F("CONNECTED") : F("NOT FOUND"));

  Serial.print(F("BUZZER   : PIN "));
  Serial.println(BUZZER_PIN);

  Serial.println(F("Send START or START_VITALS to measure."));
}

// ============================================================================
// SERIAL COMMAND DISPATCHER
// ============================================================================

void loop() {
  while (Serial.available()) {
    char c = Serial.read();

    if (c == '\r') {
      continue;
    }

    if (c == '\n') {
      command[commandPos] = '\0';

      // Trim leading/trailing whitespace
      char *cmd = command;
      while (*cmd == ' ') cmd++;
      int len = strlen(cmd);
      while (len > 0 && cmd[len - 1] == ' ') {
        cmd[--len] = '\0';
      }

      // Handle measurement triggers from Kiosk or Serial Monitor
      if (strcasecmp(cmd, "START") == 0 ||
          strcasecmp(cmd, "START_VITALS") == 0) {
        takeVitals();
      }
      else if (strcasecmp(cmd, "PING") == 0) {
        Serial.println(F("SYSTEM READY"));
      }
      else if (len > 0) {
        Serial.print(F("Unknown command: "));
        Serial.println(cmd);
      }

      commandPos = 0;
    }
    else if (commandPos < sizeof(command) - 1) {
      command[commandPos++] = c;
    }
    else {
      commandPos = 0;
    }
  }
}
