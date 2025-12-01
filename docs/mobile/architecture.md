# Mobile App Architecture (Q-Ring V1)

## Overview
- Cross-platform app (Flutter recommended)
- Layers:
  - BLE Manager (connect + parse GATT)
  - Data Processor (feature normalization, caching)
  - Local ML (optional, TensorFlow Lite)
  - UI Layer (dashboard, onboarding)
  - Sync Layer (cloud API, auth)

## Suggested folder structure (app)
lib/
  ├─ ble/
  ├─ models/
  ├─ services/
  ├─ ui/
  └─ main.dart
