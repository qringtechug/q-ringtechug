docs/whitepaper/WHITEPAPER.md
# Q-Ring V1 — Technical Whitepaper (Summary)

## Abstract
Q-Ring V1 is an emotion-sensing wearable ring that uses bio-sensing (PPG, GSR, temperature, IMU) and on-device AI to detect, predict, and help manage emotional states. This whitepaper summarizes the hardware architecture, AI approach, privacy model, and manufacturing plan for the V1 product.

## 1. Problem
Modern life causes rising stress and burnout. Existing wearables measure physical health but do not provide actionable real-time emotional intelligence. Q-Ring V1 makes emotion measurable and actionable.

## 2. Solution Overview
Q-Ring V1 combines:
- Compact sensor array (PPG, GSR, temperature, IMU)
- Low-power microcontroller with TinyML inference
- BLE connection to the Q-Link mobile app
- Cloud analytics for model improvements (opt-in only)
- Privacy-first architecture with E2E encryption

## 3. Hardware Summary
- PPG (heart rate, HRV) — MAX30102 or equivalent  
- GSR (electrodermal activity) — two micro-electrodes  
- Skin temperature sensor — TMP117 (contact)  
- IMU (3-axis accelerometer) — MPU-6050 or similar  
- MCU: nRF52840 or ESP32 (BLE + low-power)  
- Battery: small Li-Po 50–150mAh; wireless/USB charging  
- Enclosure: 3D-printed for prototypes; titanium for production

## 4. Firmware & Signal Processing
- Sampling rates: PPG 100–200Hz, GSR 50Hz, IMU 50Hz, Temp 1–10Hz  
- On-device preprocessing: filtering, motion artifact removal, HRV extraction  
- Feature extraction for ML: time-domain HRV, EDA peaks, temp deltas, movement signatures  
- BLE GATT profile for streaming features and receiving firmware updates

## 5. AI Approach
- On-device TinyML model for real-time emotion classification (calm, stressed, focused, drowsy)  
- Cloud model for deeper training and personalization (privacy-first, opt-in)  
- Personalization via 7-day calibration flow during onboarding  
- Evaluation: use public datasets (WESAD, DEAP) + internal user-labeled tests

## 6. Privacy & Security
- End-to-end encryption (BLE+cloud)  
- User owns their data; opt-in for cloud analytics  
- No identity-revealing data stored on the ring  
- GDPR-style deletion and export support

## 7. Manufacturing & Testing
- Prototype (3D print) → Alpha (PCB + enclosure) → Beta (small run 500 units) → Production (tooling)  
- Safety: Class 1 eye-safe IR if any IR emitter used; Li-Po battery protection circuits; ingress testing for wearables

## 8. Roadmap & Next Steps (High-level)
- Month 0–2: Prototype hardware + AI baseline  
- Month 3–6: Alpha testing with 50–100 users  
- Month 7–9: Beta batch (500 units) & certification  
- Month 10–12: Launch and pre-orders  

## 9. Conclusion
Q-Ring V1 uses proven sensors and modern TinyML to deliver the world’s first focused emotional-intelligence wearable. It is a practical, privacy-first device designed to improve mental well-being, productivity, and human connection.

*For detailed architecture diagrams, model descriptions, and full technical appendix, see docs/whitepaper/APPENDIX.md*
