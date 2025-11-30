# Firmware Examples — Starter Code

This folder will contain starter firmware examples for prototyping.

## Recommended examples
- `esp32_max30102_gsr/` — ESP32 example reading MAX30102 + GSR and sending via Serial/BLE
- `nrf52840_tflm_example/` — nRF52840 example running a TFLite-Micro model on features
- `sensor_testbench/` — scripts to log raw sensors to CSV for algorithm development

## How to add code
1. Create a new folder under `firmware/examples/` with the example name.
2. Add a `README.md` in each example folder with build/run instructions.
3. Commit source files (`.ino`, `.cpp`, `.c`, `platformio.ini`) into that folder.

## Example notes
- Keep examples minimal and well-commented.
- Do not commit any PII or human-subject raw datasets to the public repo.
