# Q-Ring V1 — API & BLE Specifications

**Version:** 1.0  
**Last updated:** 2025-11-30  
**Author:** Q-Ring Technologies — Joel Buyus

This document specifies the Bluetooth Low Energy (BLE) GATT profile implemented by Q-Ring V1, the mobile app ↔ cloud API endpoints, authentication model, example payloads, error handling, and versioning guidelines. Use this document for firmware, mobile, and backend integration.

---

## Table of contents
1. BLE (GATT) Overview
2. BLE Services & Characteristics (Detailed)
3. Pairing & Security
4. Mobile App → Cloud REST API
5. Authentication & Tokens
6. Example Request / Response JSON
7. Error Codes & Handling
8. API Versioning and Change Log

---

## 1. BLE (GATT) Overview

**Design goals**
- Minimize power usage with event-driven notifications.  
- Send processed feature vectors and event notifications rather than continuous raw streams where possible.  
- Support OTA firmware updates (DFU) over BLE.  
- Secure pairing and encrypted transport.

**Transport**
- Bluetooth Low Energy (BLE) 4.2 / 5.0 compatible.
- Use GATT Server on the ring; mobile acts as GATT Client.
- Preferred connection intervals: 50–200 ms (tunable based on battery vs latency needs).

---

## 2. BLE Services & Characteristics (Detailed)

> Use UUIDs either 128-bit randomly generated or vendor base + short IDs. Example UUIDs below use a fictional base `0000QRXX-0000-1000-8000-00805f9b34fb` — replace with your generated UUIDs during implementation.

### 2.1 Device Information Service (standard)
- **Service UUID:** `0000180a-0000-1000-8000-00805f9b34fb` (standard)
  - **Characteristic:** Manufacturer Name String  
    - UUID: `00002a29-0000-1000-8000-00805f9b34fb`  
    - Properties: Read  
    - Example Value: "Q-Ring Technologies"
  - **Characteristic:** Model Number String  
    - UUID: `00002a24-0000-1000-8000-00805f9b34fb`  
    - Properties: Read  
    - Example Value: "Q-Ring V1"

### 2.2 Battery Service (standard)
- **Service UUID:** `0000180f-0000-1000-8000-00805f9b34fb`
  - **Characteristic:** Battery Level  
    - UUID: `00002a19-0000-1000-8000-00805f9b34fb`  
    - Properties: Read, Notify  
    - Format: uint8 (0–100)

### 2.3 Sensor Feature Service (custom)
- **Service UUID:** `0000QR01-0000-1000-8000-00805f9b34fb` (replace `QR01` with assigned short id)
  - **Characteristic:** Feature Vector (Compressed JSON/TLV)  
    - UUID: `0000QR02-0000-1000-8000-00805f9b34fb`  
    - Properties: Notify, Read  
    - Description: Periodic feature vector containing fused sensor summary (HR, HRV metrics, GSR tonic/phasic stats, temp delta, motion summary).  
    - Suggested payload: TLV or compact JSON under 200 bytes. Example:
      ```json
      {
        "ts": 1700000000,
        "hr": 72,
        "rmssd": 24.5,
        "gsc_tonic": 1.2,
        "gsc_scr_count": 2,
        "temp_d": -0.1,
        "motion": 3
      }
      ```
  - **Characteristic:** Raw Data Stream (optional, for debug)  
    - UUID: `0000QR03-0000-1000-8000-00805f9b34fb`  
    - Properties: Notify, Read, Indicate (use sparingly due to power)  
    - Description: Optional raw PPG/GSR batches when debug mode is enabled (must be explicit opt-in).

### 2.4 Emotion Event Service (custom)
- **Service UUID:** `0000QR10-0000-1000-8000-00805f9b34fb`
  - **Characteristic:** Emotion Event  
    - UUID: `0000QR11-0000-1000-8000-00805f9b34fb`  
    - Properties: Notify, Read  
    - Description: Emits high-level emotion events detected by on-device model. Format (compact JSON):
      ```json
      {
        "ts": 1700000000,
        "event": "stressed",
        "intensity": 78,
        "confidence": 0.86
      }
      ```
  - **Characteristic:** Event History Request  
    - UUID: `0000QR12-0000-1000-8000-00805f9b34fb`  
    - Properties: Write, Read  
    - Description: Client can request last-N events; ring responds by streaming events via Emotion Event char.

### 2.5 Device Control & OTA (custom + DFU)
- **Service UUID:** `0000QR20-0000-1000-8000-00805f9b34fb`
  - **Characteristic:** Command (Write)  
    - UUID: `0000QR21-0000-1000-8000-00805f9b34fb`  
    - Properties: Write, WriteWithoutResponse  
    - Commands:
      - `{"cmd":"set_sampling","ppg":100,"gsc":20,"imu":50}`  
      - `{"cmd":"set_mode","mode":"low_power"}`  
  - **Characteristic:** DFU Control (Follow vendor DFU spec)  
    - Use standard DFU service if using Nordic/other chip vendor stack.

---

## 3. Pairing & Security

**Pairing**
- Use Secure BLE pairing with bonding (LE Secure Connections if available).  
- Implement user confirmation step on first pairing (e.g., accept pairing on phone).

**Encryption**
- BLE link-level encryption (AES-128) + application-level payload signing if necessary.  
- Maintain rotating session tokens for cloud sync.

**Device Authorization**
- Each ring has a unique device ID and public key registered during first app onboarding. The cloud verifies device ownership using this identity before accepting data.

---

## 4. Mobile App → Cloud REST API

**Base URL (example):**
https://api.qringtech.com/v1


> NOTE: For early development you can use a Firebase or AWS API Gateway endpoint.

### 4.1 Authentication (Bearer token flow)
- `POST /auth/login` — exchange email/password or OAuth provider for a JWT access token.
- `POST /auth/device/register` — register a device public key (during onboarding) — requires auth.

### 4.2 Endpoints (examples)

- **POST /devices/{deviceId}/events**
  - Description: Upload emotion events or aggregated feature summaries from the app.
  - Auth: Bearer token
  - Payload:
    ```json
    {
      "deviceId": "qr_abc123",
      "events": [
        {"ts":1700000000,"event":"stressed","intensity":78,"confidence":0.86},
        {"ts":1700000300,"event":"calm","intensity":22,"confidence":0.90}
      ]
    }
    ```
  - Response: `200 OK` `{"status":"ok","received":2}`

- **POST /devices/{deviceId}/features**
  - Description: Upload periodic feature vectors (30s/60s batches).
  - Payload example:
    ```json
    {
      "deviceId": "qr_abc123",
      "features": [
        {"ts":1700000000,"hr":72,"rmssd":24.5,"gsc_tonic":1.2,"motion":3},
        ...
      ]
    }
    ```

- **GET /users/{userId}/summary?from=TS&to=TS**
  - Description: Get aggregated daily/weekly summaries for the user.
  - Response: JSON with daily stress score, sleep quality, and top events.

- **POST /users/{userId}/consent**
  - Description: Record user consent for data sharing and analytics.
  - Payload: `{"consent":true,"scope":["cloud_training","anonymous_research"]}`

- **POST /webhook/event**
  - Description: (Optional) Partners can register webhook endpoints to receive anonymized population-level triggers (consent required).

---

## 5. Authentication & Tokens

**Auth model**
- Use JWT (access tokens short-lived, refresh tokens longer).  
- Protect endpoints with HTTPS/TLS 1.2+.

**Token flow**
1. User authenticates (email/pass or OAuth) → `POST /auth/login` → receives `access_token` (exp 15m) and `refresh_token` (exp 30d).
2. Mobile app uses access_token for API calls, refreshes when expired.

**Device registration**
- During onboarding the app generates a device key-pair (ED25519) and sends the public key to `POST /auth/device/register` signed with user token. The cloud binds deviceId ↔ public key.

---

## 6. Example Request / Response JSON

**Upload event example**
- Request:
POST /devices/qr_abc123/events
Authorization: Bearer <access_token>
Content-Type: application/json

{
"deviceId":"qr_abc123",
"events":[
{"ts":1700000000,"event":"stressed","intensity":78,"confidence":0.86}
]
}
- Response:
200 OK
{
"status":"ok",
"received":1,
"serverTime":1700000012
}    

**Error example**
- Response:
401 Unauthorized
{
"error":"invalid_token",
"message":"Access token expired or invalid"
}

---

## 7. Error Codes & Handling

| HTTP Code | Error Key | Description |
|----------:|----------:|------------|
| 400 | bad_request | Malformed JSON or missing fields |
| 401 | invalid_token | Token missing/expired |
| 403 | forbidden | User lacks permission |
| 404 | not_found | Device or resource not found |
| 409 | conflict | Device already registered |
| 500 | server_error | Unexpected server error (retry advised) |

**Client retry recommendations**
- For 5xx responses: exponential backoff (retry up to 3 times).  
- For 429 (rate limit): follow `Retry-After` header.

---

## 8. API Versioning & Change Log

**Versioning**
- Use path versioning: `/v1/` then `/v2/` for breaking changes.  
- Maintain backward compatibility where possible; deprecate endpoints with 90-day notice.

**Change log**
- Keep a `docs/api/CHANGELOG.md` documenting changes to services, characteristics, and payload formats.

---

## 9. Developer Notes & Best Practices

- Keep BLE payloads compact. Prefer binary TLV for high-frequency features; use JSON for event-level data.  
- Minimize sensitive data in cloud by storing aggregated features rather than raw biosignals unless explicit user consent.  
- Document exact UUIDs used in production and rotate ephemeral keys for secure pairing.  
- Add tests for BLE parsing logic and mock endpoints for backend integration tests.

---

## 10. Useful references
- Bluetooth Core Spec (GATT): https://www.bluetooth.com/specifications/gatt/  
- RFC 7519 — JSON Web Token (JWT)  
- OWASP Top 10 for API security  
- Nordic DFU documentation (if using nRF52)  
- TFLite Micro for TinyML on-device inference

---

**End of Q-Ring V1 API & BLE specification (v1.0).**
