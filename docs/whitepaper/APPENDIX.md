# Q-Ring V1 — Technical Appendix (Full)

> Detailed technical appendix for engineers, investors, and partners.  
> Contains hardware specs, firmware architecture, ML architecture, data flows, BOM, power budgets, testing and certification notes, security, and calibration logic.

---

## Table of Contents

1. Hardware Specifications
2. Bill of Materials (BOM)
3. PCB & Mechanical Layout Notes
4. Firmware Architecture & Data Flow
5. Signal Processing & Feature Extraction
6. Machine Learning Architecture & Training Pipeline
7. Data Pipeline & Storage Design
8. Calibration & Personalization Logic
9. Power Budget & Battery Management
10. Testing, Validation & QA Procedures
11. Regulatory, Safety & Certification Notes
12. Security & Privacy Design
13. Manufacturing Notes & Assembly Flow
14. Known Limitations & Future Work
15. References & Resources

---

## 1. Hardware Specifications

**Form factor**
- Wearable ring: internal cavity dimension (prototype): 22 mm inner circumference typical for size M ring; shell outer diameter ~20–26 mm depending on design.
- Prototype shell: resin 3D-printed for fit testing. Production shell: titanium or medical-grade stainless steel with insulating interior.

**Sensor stack (recommended components for V1 prototype)**
- PPG (Photoplethysmography): MAX30102 or MAX30105 (optical HR/SpO2 sensor)  
  - Sampling: 100–200 Hz (PPG raw), on-device preprocessing to compute BPM and HRV windows.
- GSR (Electrodermal Activity): two-electrode dry-contact measurement with high-input-impedance instrumentation amplifier (e.g., TI INA333 or equivalent).  
  - Sampling: 10–50 Hz.
- Skin temperature: TMP117 or similar precision contact thermistor IC.  
  - Sampling: 1–10 Hz.
- IMU (accelerometer ± gyro optional): MPU6050 or ICM-20948 for 6/9-axis motion.  
  - Sampling: 50–100 Hz for micro-motion detection.
- Haptics: coin vibration motor or LRA (linear resonant actuator) for micro-notifications.
- LED indicator: single RGB or bi-color (optional). Avoid lasers; only use eye-safe class 1 diffused IR emitter if required.
- MCU (prototype dev): nRF52840 (recommended for BLE, low-power, and sufficient flash for TFLite-Micro) OR ESP32 for rapid prototyping (Note: ESP32 has higher active power).  
- Power: LiPo 3.7V 50–150 mAh (prototype), include protection IC (battery fuel gauge optional).  
- Charging: USB-C or magnetic pogo-pin + small charging/protection board (TP4056 for single-cell LiPo prototypes).
- Memory/Storage: Onboard flash for firmware and small local logs; optional external QSPI flash for larger local caches.
- PCB constraints: flexible/rigid-flex for ring form is preferred for later miniaturization.

**Environmental & materials**
- Skin-safe coatings for electrodes (gold-plating/Ag/AgCl pads if needed).  
- IP rating target for production: IP67 (splash & dust resistant) — prototype may be lower.

---

## 2. Bill of Materials (BOM) (Prototype-level parts & cost estimates)

| Component | Part Example | Qty | Est Unit Cost (USD) |
|-----------|--------------|-----:|---------------------:|
| MCU dev board | nRF52840 dev kit | 1 | $20–$35 |
| PPG sensor | MAX30102 module | 1 | $5–$15 |
| GSR electrodes | Custom dry electrodes | 2 | $2–$8 |
| Temperature sensor | TMP117 | 1 | $3–$10 |
| IMU | MPU6050 module | 1 | $2–$10 |
| Vibration motor | Coin motor or LRA | 1 | $1–$6 |
| Battery | LiPo 50–150 mAh | 1 | $3–$8 |
| Charger board | TP4056 module | 1 | $1–$3 |
| Small PCB/flex | Prototype PCB | 1 | $10–$40 |
| Enclosure | 3D print resin | 1 | $2–$30 |
| Connectors / misc | wires, pads | - | $5–$10 |

**Estimated prototype BOM per unit:** $50–$150 (prototype scale).  
**Estimated production BOM per unit (500–5000 runs):** $24–$48 depending on volume and custom parts.

---

## 3. PCB & Mechanical Layout Notes

**PCB form factor**
- For prototyping: use a small rigid PCB that fits inside a larger 3D-printed shell.  
- For miniaturization: transition to rigid-flex PCB that wraps the finger curvature. Place sensors on the inner surface with appropriate openings in the shell for electrodes and optical window for PPG.

**Sensor placement**
- PPG: inner ring surface in contact with skin; ensure optical isolation from ambient light and a small press-fit cavity for lens to reduce motion artifacts.
- GSR: two electrodes spaced ~8–12 mm along inner circumference to ensure proper skin contact.
- IMU: central location near ring mass center; compensation for palm/wrist gestures in software.
- Battery: flat pouch cell under central module area; ensure safe placement with thermal isolation from sensors.

**Thermal & mechanical**
- Use silicone or thin polymer liner inside ring to protect electronics and improve contact.
- Consider metal shielding and isolation between battery and sensors.
- Provide small pogo-pin or magnetic contacts for charging access if not wireless.

---

## 4. Firmware Architecture & Data Flow

**High-level modules**
1. **Bootloader / OTA support**  
   - Minimal bootloader allowing firmware updates via BLE DFU (Device Firmware Update) or button-triggered maintenance mode.

2. **Sensor Drivers**  
   - Drivers for MAX30102, INA amplifier (GSR), TMP117, IMU.

3. **Signal Preprocessing**  
   - Filtering (low-pass, band-pass), DC removal for PPG, baseline wander removal for GSR, calibration offsets.

4. **Feature Extraction**  
   - HR and HRV windows (time-domain features: RMSSD, SDNN, pNN50), PPG peak detection, GSR tonic/phasic decomposition (SCL and SCR detection), temp deltas, motion counts, spectral features.

5. **On-device ML Inference (TinyML)**  
   - TFLite-Micro binary executes inference on preprocessed features. Keep model small (<100–300 KB ideally).

6. **BLE Communication Manager**  
   - GATT profile to expose device metadata, battery, sample features, and emotion event notifications. Secure pairing.

7. **Power Manager**  
   - Sleep states, sensor duty cycling, adaptive sampling (increase sampling on suspected events), watchdog.

8. **Local Logging**  
   - Ring stores minimal last-X minutes of features when disconnected; bulk transfer when phone reconnects.

**Data flow (runtime)**
- Sensors → Preprocessing → Feature extraction → On-device inference (optional) → Event generation/notification → BLE transmission to app → App processes & logs → Optional cloud sync when allowed.

**Sample BLE GATT characteristics (recommendation)**
- Device Information Service: model, fw version.  
- Battery Service: level, charge status.  
- Sensor Service: new-feature notifications (JSON-lite or TLV encoded).  
- Emotion Event Service: event type (stressed/calm/focused), intensity (0–100), timestamp.

---

## 5. Signal Processing & Feature Extraction

**PPG processing**
- Bandpass 0.5–5 Hz for heart rate; use adaptive peak detection (Pan-Tompkins variant tuned for PPG).
- HRV windows: 30s to 5min windows; compute RMSSD, SDNN, pNN50.
- Motion artifact removal: use IMU to detect high-motion intervals and suppress PPG-derived features in those intervals or weight them low.

**GSR processing**
- Use a two-component model:
  - Tonic (SCL) baseline (slowly varying)
  - Phasic (SCR) event detection (sharp rises > threshold µS)
- Compute SCR count rate, average amplitude, and recovery time.

**Temperature**
- Monitor short-term deltas; sudden drops or rises correlated with stress events.

**IMU**
- Micro-motion features: frequency of small shakes, gesture detection, activity classification (static, walking, running).

**Feature fusion**
- Create time-synced feature vectors every N seconds (e.g., every 5s or 10s), comprising HRV metrics, GSR stats, temp delta, motion summary. Normalize features per user baseline during calibration.

---

## 6. Machine Learning Architecture & Training Pipeline

**Model approach (two-tier)**
- **Edge model (TinyML):** Small classifier/regressor for immediate inference (outputs: emotional state categorical + intensity). Typical model types: small CNN over time windows, LSTM (tiny RNN), or ensemble of boosted trees on extracted features converted for micro inference (e.g., decision forests converted to TFLite).
- **Cloud model:** Larger recurrent network (CNN-LSTM hybrid) that learns richer temporal dependencies and personalization; used to periodically retrain and push updated quantized models to devices.

**Input**
- Preprocessed and normalized feature vectors (5–10s aggregation). Optionally include context variables (time-of-day, recent sleep score) from app.

**Outputs**
- Emotion class probabilities: {calm, focused, stressed, anxious, drowsy}.  
- Continuous stress score (0–100).  
- Event flags: rapid stress spike, sustained elevated state, possible panic event.

**Training data**
- Public datasets (initial training): WESAD, DEAP, AMIGOS, SWELL.  
- Proprietary labeled data: collected via pilot testers with simultaneous self-report and ground-truth events (task-induced stress tasks).

**Evaluation metrics**
- Class accuracy, F1-score per class, AUC for detection tasks, false positive rate for stress alerts (must be low for trust).

**Model lifecycle**
1. Pretrain on public datasets for baseline behavior.  
2. Fine-tune using small personal datasets via transfer learning (7-day calibration).  
3. Evaluate, quantize, and export to TFLite.  
4. Periodically retrain on cloud using aggregated anonymized datasets (opt-in) and push improved models.

**Model size & latency**
- Target tiny model: <250 KB binary; inference time <100–200 ms on MCU where possible. If MCU cannot run TinyML, perform inference on phone app (edge-on-phone).

---

## 7. Data Pipeline & Storage Design

**On-device**
- Minimal local buffer (last 12–24 hours of compressed features). Raw biosignal storage by default OFF (sensitive). Use ring local storage for temporary caching.

**Mobile app**
- Stores local history and provides UI, onboarding, calibration flow and consent workflows.
- Performs heavier on-phone inference if needed and syncs aggregate data (daily summaries) to cloud when user consents.

**Cloud**
- Authentication: OAuth2 via Firebase Auth or AWS Cognito.  
- Storage: Firestore or DynamoDB for event summaries; S3 for any large anonymized datasets (opt-in only).  
- ML infra: GPU-enabled training cluster (Google Cloud, AWS).  
- DevOps: CI/CD pipeline for model packaging and app updates.

**Data retention & export**
- Allow user to export or delete all personal data; default retention policy 90 days for cloud-profiles unless user selects longer.

---

## 8. Calibration & Personalization Logic

**7-day onboarding calibration**
- Baseline collection: during the first 7 days, collect passive sensor data and prompt user for 3–6 short contextual self-reports per day (e.g., “How stressed are you now?” 1–5).
- Use collected data to compute personal baseline stats and normalize features (z-score per feature).
- Fine-tune on-device model with per-user small retraining or apply personalized threshold adjustments for alerts.

**Adaptive thresholds**
- Use running mean/SD for each user for features such as tonic GSR and HRV; generate alerts based on deviations (e.g., >1.5 SD sustained for N minutes).

**Personal preference**
- Let user set sensitivity slider (Conservative / Balanced / Sensitive) to reduce false positives vs. catch more episodes.

---

## 9. Power Budget & Battery Management

**Typical sampling & duty**
- Idle sampling: PPG low-duty (e.g., every 10s), GSR periodic, IMU low-power wake-on-motion.
- Active sampling: On detected events increase PPG to 100–200 Hz for higher fidelity windows.

**Power estimates (prototype)**
- MCU active: 8–15 mA average (nRF52840 typical active draw varies)  
- MAX30102 during sampling: ~1–3 mA average depending on LED duty cycle  
- GSR sensor: ~0.5–1.5 mA (depends on amplifier)  
- Vibration motor: high peak current (100–200 mA) for short bursts  
- Idle deep-sleep: µA range with proper power gating

**Goal**
- Typical user battery life target: 48–96 hours with conservative sampling and optimized duty cycling on a 100–150 mAh battery.

**Charging**
- 30–90 minute charging depending on charger and battery size. Include charging protection.

---

## 10. Testing, Validation & QA Procedures

**Unit testing**
- Sensor driver unit tests on bench using simulated signals.
- Signal processing tests with recorded test vectors.

**Integration testing**
- End-to-end streaming from ring → app. Validate sampling rates and data integrity.

**Clinical/Field testing**
- Pilot with 30–100 users across demographics to measure model accuracy and false positive rates. Gold standard: combine self-report, validated questionnaire (PSS/STAI), and controlled stress tasks.

**Environmental testing**
- Thermal cycling, sweat & moisture tests, drop tests, and skin irritation tests.

**Reliability**
- Battery cycle testing (200+ cycles), connector robustness, and long-term sensor drift checks.

---

## 11. Regulatory, Safety & Certification Notes

**Electronics safety**
- Battery safety: conform to UN38.3 during shipping and transport.  
- EMC/EMI: plan to certify for FCC (US), CE (EU), and relevant local certifications.

**Medical claims**
- Q-Ring V1 is an informational wellness device — do not make medical claims without clinical validation and appropriate medical device regulatory approval (FDA/CE medical device route is very different). Keep marketing language to *wellness* and *emotional awareness*.

**Laser & optical safety**
- If using IR emitters, ensure they are Class 1 eye-safe and follow IEC 60825.

**Data protection**
- Plan GDPR compliance for EU users and follow regional data protection laws (e.g., Uganda may have different laws). Provide clear privacy policy and consent mechanisms.

---

## 12. Security & Privacy Design

**Communication security**
- BLE pairing with secure bonding (AES-128).  
- Use ephemeral session keys for each session.  
- TLS 1.2/1.3 for cloud communications.

**Data security**
- Local device encryption for cached data (AES-256).  
- Cloud data encrypted at rest and in transit.  
- Minimal Personally Identifiable Information (PII) — store email only for authentication and billing, with user consent.

**Access controls**
- Role-based access for backend admin portals.  
- Audit logs for any data access.

**Vulnerability response**
- SECURITY.md (repo) with disclosure contact.  
- Maintain updateable firmware and DFU function to patch vulnerabilities.

---

## 13. Manufacturing Notes & Assembly Flow

**Prototype → Alpha → Beta → Production**
- Prototype: manual assembly and 3D printed cases (1–10 units).
- Alpha: small-run PCBs (~10–50 units) assembled with hand-solder or local PCB assembly house.
- Beta: 500–1000 units using contract manufacturer (CM) with picked-and-placed SMT, reflow soldering.
- Production: tooling for injection-molded cases, certified materials, automated assembly.

**Assembly flow for Beta**
1. PCB fabrication + pick/place SMT.  
2. Visual inspection & reflow QA.  
3. Through-hole/manual solder for battery/pogo pin placement.  
4. Enclosure assembly and potting/seal as needed.  
5. Device burn-in and calibration (automated test jig).  
6. Packaging and shipping.

---

## 14. Known Limitations & Future Work

**Limitations V1**
- Emotion labels are probabilistic and not clinical diagnoses.  
- Sensor accuracy impacted by strong motion/artifacts.  
- Battery life trade-off vs sampling fidelity.  
- On-device model capacity limited—complex inference may need phone or cloud.

**Future work**
- Rigid-flex PCB miniaturization.  
- Improved sensor fusion with additional modalities.  
- Federated learning for privacy-preserving personalization.  
- Explore non-invasive neural intent detection (research stage).  
- Photonic communication research track (long-term).

---

## 15. References & Resources

- WESAD dataset (Wearable Stress and Affect Detection).  
- DEAP (Dataset for emotion analysis using physiological signals).  
- TensorFlow Lite for Microcontrollers documentation.  
- Nordic Semiconductor (nRF52840) datasheets.  
- MAX30102 datasheet and ANs for PPG.  
- IEC 60825 (optical safety) and relevant battery safety standards (UN38.3).

---

### Appendix Maintenance
- Keep this APPENDIX.md versioned: update when new prototypes, BOM, or test results change.  
- Add CSV or XLS test result summaries into `docs/whitepaper/data/` (private storage for sensitive raw data — see security notes).

---

*Prepared for Q-Ring V1 prototype development and investor-facing technical review.*

