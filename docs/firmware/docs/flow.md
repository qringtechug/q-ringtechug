# Firmware Architecture & Data Flow

## Overview
Firmware is organized into modular components to simplify testing and upgrades. The main runtime loop executes a low-power sleep cycle and wakes for sensor sampling or BLE events.

## Core Modules
1. **Bootloader**
   - Minimal bootloader supporting DFU (OTA).
   - Verifies firmware integrity and jumps to application.

2. **Platform Layer**
   - HAL (Hardware Abstraction Layer) for MCU peripherals.
   - I2C/SPI/UART drivers as needed.

3. **Sensor Drivers**
   - PPG driver (MAX30102/05)
   - GSR driver (instrumentation amplifier + ADC)
   - Temperature driver (TMP117)
   - IMU driver (MPU6050 / ICM-20948)

4. **Signal Processing**
   - Filtering (low-pass, band-pass)
   - Motion artifact detection using IMU
   - HR peak detection and HRV calculation
   - GSR tonic/phasic decomposition

5. **Feature Extraction**
   - Aggregate metrics every window (e.g., 5s or 10s)
   - Create compact feature vectors for ML or BLE transfer:
     `{ ts, hr, rmssd, gsc_tonic, scr_count, temp_d, motion_score }`

6. **ML Inference (TinyML)**
   - Load TFLite-Micro model (if MCU has capacity)
   - Run inference on feature vectors and output emotion event

7. **BLE Communication**
   - Advertising, pairing, bonding
   - GATT services for device info, battery, sensor features, emotion events
   - Efficient notifications (event-driven)

8. **Power Manager**
   - Sleep modes, sensor duty cycling, adaptive sampling
   - Low-power timers for periodic wake-ups
   - Wake-on-motion strategy via IMU interrupt

9. **Local Storage / Logging**
   - Circular buffer for last N feature vectors when disconnected
   - Secure storage of device metadata and pairing info

## Typical Runtime Flow (simplified)
1. Boot -> Initialize drivers -> Load config
2. Enter low-power sleep (watchdog active)
3. Wake on timer or IMU interrupt
4. Sample sensors (PPG, GSR, Temp, IMU)
5. Preprocess signals -> extract features
6. If event detected or periodic update -> run inference (optional)
7. If connected -> send feature vector or event via BLE notification
8. Return to low-power sleep

## Debugging & Logging
- Use serial (USB or UART) for debug logs during development.
- Keep verbose logging off for battery tests.

## Testing hooks
- Self-test on boot to verify sensors and battery
- Calibration routine invoked during onboarding
