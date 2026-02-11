# CREST Gold Award: Aegis Smart Medicine Reminder System

## Project overview
Aegis is a connected medicine reminder system designed to help older adults take medication on time while giving families and caregivers clear visibility. The solution combines a Flutter mobile app, a cloud backend (Firebase/Firestore), and an ESP32-based physical reminder device with time-based compartments and status feedback.

## Problem statement
Many older adults manage multiple prescriptions with different schedules. Missed or duplicated doses can lead to health risks, but existing solutions are often too complex, lack physical confirmation, or do not provide family oversight. Aegis addresses this with a simple daily schedule, a physical confirmation button, and real-time tracking in the app.

## Aims and success criteria
- Create a reliable schedule for medicines by day and time slot.
- Provide a physical device that lights the correct compartment and logs “taken” events.
- Enable easy device setup (WiFi credentials, device pairing) via Bluetooth.
- Allow multiple devices per user for different locations or people.
- Provide a clear caregiver view of adherence.

## Background research (summary)
- Medication adherence drops when schedules are complex, alarms are ignored, or reminders are not tangible.
- Older adults benefit from simple, large, and predictable interfaces.
- Caregivers need remote confirmation, not just reminders.
- A combined hardware + app approach increases trust and usability.

## System design
### Architecture
- Mobile app (Flutter): scheduling, device pairing, tracking, UI.
- Cloud backend (Firebase/Firestore): prescriptions, devices, medicine_taken events.
- ESP32 hardware: RTC-driven reminders, LEDs per time slot, physical “taken” button.

### Data flow (high level)
1. User logs in or signs up (Firebase Auth).
2. App pairs with device using Bluetooth and sends WiFi credentials.
3. Device connects to WiFi and publishes its unique device ID.
4. App assigns device ID to a user in Firestore.
5. Prescriptions are created/edited in the app and saved to Firestore.
6. Device polls Firestore or listens for updates to sync schedules.
7. At scheduled times, device alerts (LEDs) and user confirms via button.
8. Device writes a “medicine_taken” entry to Firestore.
9. App shows live adherence status for the user and caregivers.

## Hardware design
### Core components
- ESP32 for WiFi/Bluetooth connectivity.
- RTC (DS3231) for reliable timekeeping.
- LED indicators for time slots (morning/afternoon/night).
- Physical confirmation button.
- Medication compartments for each day and time.

### Hardware behavior
- RTC checks current time and compares to schedules.
- LED signals the slot due at the current time.
- A button press records the dose as taken in Firestore.

## Firmware design (ESP32)
### Key features based on `lib/esp_code_updated.ino` and related firmware
- Reads schedules from Firestore collections (`devices`, `prescriptions`, `medicine_taken`).
- Uses unique device ID and Firestore REST APIs.
- Syncs the active schedule and tracks if medicine is already marked.
- Records “taken” events with timestamp, day, and time slot.
- Supports WiFi setup and device pairing.

## App design (Flutter)
### Core screens and workflows
- Auth: login/sign-up using Firebase.
- Home: device list and quick access to schedules.
- Device setup: Bluetooth pairing and WiFi credential transfer.
- Schedule management: prescriptions by day and time slot.
- Box schedule: simplified weekly grid for quick setup.
- Tracking: “taken” status synced from hardware and in-app actions.

### App UI/UX choices
- Large, readable typography and clear color contrast.
- Simple “Morning / Afternoon / Night” slots.
- Visual emphasis on “today” to reduce confusion.
- Settings for volume, dark mode, and caregiver mode.

## Testing and validation plan
- **Connectivity tests:** Bluetooth pairing, WiFi provisioning, Firestore sync.
- **Schedule accuracy:** verify matching of day/time slot and tolerance windows.
- **Button reliability:** confirm “taken” logging under repeated use.
- **Edge cases:** device offline, late medication, schedule changes mid-day.
- **Usability checks:** older adult task completion without assistance.

## Results (current state)
- Flutter app supports multi-device management and prescription scheduling.
- ESP32 firmware can fetch schedules and post taken events.
- Firestore data model supports device ownership and adherence history.

## Evaluation
The system meets the core requirement of linking physical confirmation with cloud tracking. The combination of a tangible device and a simple app helps reduce confusion and supports caregivers. The largest risk areas are WiFi provisioning reliability and ensuring the user presses the button consistently.

## Ethical, privacy, and safety considerations
- Only necessary data is stored (prescriptions, device ID, timestamps).
- User data is tied to Firebase authentication.
- Caregiver access should be permissioned by the user.
- Avoid false assurance: clearly show “no confirmation received” when a dose is missed.

## Future improvements
- Offline caching and retry logic for taken events.
- Push notifications for missed doses.
- Voice prompts for accessibility.
- Battery backup and enclosure improvements.
- Dashboard for caregivers with trends and alerts.

## Conclusion
Aegis demonstrates a practical, user-centered medicine reminder system combining IoT hardware with a mobile app. It addresses adherence with both physical cues and digital tracking, helping older adults stay independent while giving caregivers peace of mind.
