#include <WiFi.h>
#include <Wire.h>
#include <RTClib.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>

// Firestore Configuration
const char* API_KEY = "AIzaSyDyQ5GgcYMzSk2fjrJXAQeFn5NlmIYphp0";
String projectId = "smart-medicine-eb37a";

// Collections
String devicesCollection = "devices";
String prescriptionsCollection = "prescriptions";
String medicineTakenCollection = "medicine_taken";

// URLs
String getDeviceURL, createDeviceURL, getPrescriptionsURL, createMedicineTakenURL;

// WiFi credentials - Static values
const char* WIFI_SSID = "raghu";
const char* WIFI_PASSWORD = "12345678";

RTC_DS3231 rtc;

bool handleLoop = false;
String deviceID;
String uid = "";

// Physical buttons
#define BUTTON_TAKEN_PIN      17  // TX2 pin
#define LED_PIN               13

// Button states
bool buttonTakenPressed = false;
unsigned long lastButtonPress = 0;

// Medicine tracking
struct Prescription {
  String id;
  String medicineName;
  String time;
  String timeSlot;
  String selectedDays;
  int doseQuantity;
};

Prescription prescriptions[20];
int prescriptionCount = 0;
bool alreadyAlerted[20][7][3];  // [prescription][day][timeSlot]

// === Time and Day Helpers ===
String getCurrentDay() {
  DateTime now = rtc.now();
  switch (now.dayOfTheWeek()) {
    case 1: return "Monday";
    case 2: return "Tuesday";
    case 3: return "Wednesday";
    case 4: return "Thursday";
    case 5: return "Friday";
    case 6: return "Saturday";
    case 0: return "Sunday";
    default: return "Monday";
  }
}

String getCurrentTimeSlot() {
  DateTime now = rtc.now();
  int hour = now.hour();
  if (hour < 12) return "Morning";
  else if (hour < 16) return "Afternoon";
  else return "Night";
}

String getTimeString() {
  DateTime now = rtc.now();
  char buf[6];
  sprintf(buf, "%02d:%02d", now.hour(), now.minute());
  return String(buf);
}

// === Firestore Functions ===
bool checkAndCreateDevice() {
  Serial.println("🔍 Checking if device exists in Firebase...");
  HTTPClient http;
  http.begin(getDeviceURL);
  int code = http.GET();
  
  if (code == 200) {
    // Device exists, fetch UID
    String payload = http.getString();
    StaticJsonDocument<1024> doc;
    deserializeJson(doc, payload);
    
    if (doc["fields"]["uid"]["stringValue"]) {
      uid = doc["fields"]["uid"]["stringValue"].as<String>();
      Serial.println("✅ Device found! UID: " + uid);
      http.end();
      return true;
    } else {
      Serial.println("⚠️ Device exists but no UID field found");
      http.end();
      return false;
    }
  } else if (code == 404) {
    // Device doesn't exist, create it
    Serial.println("📝 Device not found, creating new device...");
    http.end();
    return createDevice();
  }
  
  Serial.println("❌ Failed to check device status. Code: " + String(code));
  String response = http.getString();
  Serial.println("Response: " + response);
  http.end();
  return false;
}

bool createDevice() {
  HTTPClient http;
  http.begin(createDeviceURL);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<512> doc;
  auto fields = doc.createNestedObject("fields");
  
  // Create device document with basic info
  fields["deviceId"]["stringValue"] = deviceID;
  fields["name"]["stringValue"] = "ESP32 Medicine Tracker";
  fields["type"]["stringValue"] = "medicine_tracker";
  fields["status"]["stringValue"] = "active";
  
  // Proper timestamp format for Firestore
  String timestamp = rtc.now().timestamp(DateTime::TIMESTAMP_FULL);
  fields["createdAt"]["timestampValue"] = timestamp;
  fields["lastSeen"]["timestampValue"] = timestamp;
  
  // Note: uid will be set when user connects the device in the app
  fields["uid"]["stringValue"] = "";  // Empty initially
  
  String body;
  serializeJson(doc, body);
  
  int code = http.POST(body);
  if (code == 200) {
    Serial.println("✅ Device created successfully!");
    Serial.println("📱 Please connect this device in the app to assign it to a user");
    http.end();
    return true;
  } else {
    Serial.println("❌ Failed to create device. Code: " + String(code));
    String response = http.getString();
    Serial.println("Response: " + response);
    http.end();
    return false;
  }
}

bool fetchUID() {
  HTTPClient http;
  http.begin(getDeviceURL);
  int code = http.GET();
  
  if (code == 200) {
    String payload = http.getString();
    StaticJsonDocument<1024> doc;
    deserializeJson(doc, payload);
    
    if (doc["fields"]["uid"]["stringValue"]) {
      String fetchedUID = doc["fields"]["uid"]["stringValue"].as<String>();
      if (fetchedUID.length() > 0) {
        uid = fetchedUID;
        Serial.println("✅ UID fetched: " + uid);
        http.end();
        return true;
      } else {
        Serial.println("⚠️ Device exists but no UID assigned yet");
        Serial.println("📱 Please connect this device in the app");
        http.end();
        return false;
      }
    }
  }
  
  Serial.println("❌ Failed to fetch UID");
  http.end();
  return false;
}

bool fetchPrescriptions() {
  if (uid.length() == 0) {
    Serial.println("⚠️ No UID available, cannot fetch prescriptions");
    return false;
  }

  Serial.println("🔍 Fetching prescriptions for UID: " + uid);

  HTTPClient http;
  http.begin(getPrescriptionsURL);
  http.addHeader("Content-Type", "application/json");

  // Build Firestore structured query
  StaticJsonDocument<512> queryDoc;
  auto structuredQuery = queryDoc.createNestedObject("structuredQuery");
  structuredQuery["from"][0]["collectionId"] = prescriptionsCollection;

  auto whereClause = structuredQuery.createNestedObject("where");
  auto filter = whereClause.createNestedObject("fieldFilter");
  filter["field"]["fieldPath"] = "uid";
  filter["op"] = "EQUAL";
  filter["value"]["stringValue"] = uid;

  String queryBody;
  serializeJson(queryDoc, queryBody);

  Serial.println("📤 Query: " + queryBody);

  int code = http.POST(queryBody);
  if (code != 200) {
    Serial.println("❌ Failed to fetch prescriptions. Code: " + String(code));
    Serial.println(http.getString());
    http.end();
    return false;
  }

  // Parse response
  String payload = http.getString();
  Serial.println("📥 Response: " + payload);

  StaticJsonDocument<4096> doc;  // increase if needed
  DeserializationError err = deserializeJson(doc, payload);
  if (err) {
    Serial.println("❌ JSON parse failed: " + String(err.c_str()));
    http.end();
    return false;
  }

  prescriptionCount = 0;

  // Firestore runQuery returns an array of results
  for (JsonObject result : doc.as<JsonArray>()) {
    if (!result.containsKey("document")) continue;

    JsonObject document = result["document"];
    JsonObject fields = document["fields"];

    if (prescriptionCount >= 20) break;

    prescriptions[prescriptionCount].id = document["name"].as<String>();
    prescriptions[prescriptionCount].medicineName = fields["medicineName"]["stringValue"].as<String>();
    prescriptions[prescriptionCount].time = fields["time"]["stringValue"].as<String>();
    prescriptions[prescriptionCount].timeSlot = fields["timeSlot"]["stringValue"].as<String>();
    prescriptions[prescriptionCount].doseQuantity = fields["doseQuantity"]["integerValue"].as<int>();

    // Parse selectedDays array
    String selectedDays = "";
    if (fields["selectedDays"]["arrayValue"]["values"]) {
      for (JsonVariant day : fields["selectedDays"]["arrayValue"]["values"].as<JsonArray>()) {
        if (selectedDays.length() > 0) selectedDays += ",";
        selectedDays += day["stringValue"].as<String>();
      }
    }
    prescriptions[prescriptionCount].selectedDays = selectedDays;

    Serial.println("✅ Added prescription: " + prescriptions[prescriptionCount].medicineName +
                   " at " + prescriptions[prescriptionCount].timeSlot +
                   " (Days: " + prescriptions[prescriptionCount].selectedDays + ")");

    prescriptionCount++;
  }

  Serial.println("📊 Total prescriptions fetched: " + String(prescriptionCount));
  http.end();
  return true;
}


void markMedicineTaken(String prescriptionId, String day, String timeSlot) {
  // Generate unique document ID
  String documentId = String(millis()) + "_" + String(random(1000, 9999));
  String url = "https://firestore.googleapis.com/v1/projects/" + projectId +
               "/databases/(default)/documents/" + medicineTakenCollection +
               "/" + documentId + "?key=" + API_KEY;
  
  Serial.println("📝 Creating medicine taken record: " + documentId);
  Serial.println("🔗 URL: " + url);
  
  HTTPClient http;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<512> doc;
  auto fields = doc.createNestedObject("fields");
  
  // Generate unique ID
  String takenId = String(millis()) + "_" + prescriptionId;
  fields["id"]["stringValue"] = takenId;
  fields["prescriptionId"]["stringValue"] = prescriptionId;
  fields["deviceId"]["stringValue"] = deviceID;
  fields["uid"]["stringValue"] = uid;
  fields["day"]["stringValue"] = day;
  fields["timeSlot"]["stringValue"] = timeSlot;
  
  // Current timestamp in proper Firestore format
  String timestamp = rtc.now().timestamp(DateTime::TIMESTAMP_FULL);
  fields["takenAt"]["timestampValue"] = timestamp;
  
  String body;
  serializeJson(doc, body);
  
  Serial.println("📤 Request body: " + body);
  
  int code = http.PUT(body);  // Use PUT for creating document with specific ID
  
  if (code == 200) {
    Serial.println("✅ Medicine marked as taken: " + prescriptionId);
    Serial.println("📅 Day: " + day + " | Time Slot: " + timeSlot);
    // Blink LED to confirm
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
  } else {
    Serial.println("❌ Failed to mark medicine taken. Code: " + String(code));
    String response = http.getString();
    Serial.println("Response: " + response);
  }
  
  http.end();
}

// Mark all medicines for a specific time slot
void markAllMedicinesForTimeSlot(String timeSlot) {
  String currentDay = getCurrentDay();
  int markedCount = 0;
  
  Serial.println("🔍 Looking for medicines for " + currentDay + " " + timeSlot + "...");
  Serial.println("📊 Total prescriptions loaded: " + String(prescriptionCount));
  
  for (int i = 0; i < prescriptionCount; i++) {
    Serial.println("💊 Checking: " + prescriptions[i].medicineName + 
                  " | Days: " + prescriptions[i].selectedDays + 
                  " | TimeSlot: " + prescriptions[i].timeSlot);
    
    // Check if this prescription is for today and this time slot
    if (prescriptions[i].selectedDays.indexOf(currentDay) != -1 && 
        prescriptions[i].timeSlot == timeSlot) {
      
      int dayIndex = getDayIndex(currentDay);
      int timeSlotIndex = getTimeSlotIndex(timeSlot);
      
      // Only mark if not already marked
      if (!alreadyAlerted[i][dayIndex][timeSlotIndex]) {
        Serial.println("✅ Marking: " + prescriptions[i].medicineName);
        markMedicineTaken(prescriptions[i].id, currentDay, timeSlot);
        alreadyAlerted[i][dayIndex][timeSlotIndex] = true;
        markedCount++;
      } else {
        Serial.println("⚠️ Already marked: " + prescriptions[i].medicineName);
      }
    }
  }
  
  Serial.println("✅ Marked " + String(markedCount) + " medicines for " + timeSlot);
}

// === Button Handling ===
void checkButtons() {
  // Check medicine taken button
  if (digitalRead(BUTTON_TAKEN_PIN) == LOW && !buttonTakenPressed) {
    buttonTakenPressed = true;
    lastButtonPress = millis();
    
    // Get current time slot automatically
    String currentTimeSlot = getCurrentTimeSlot();
    String currentDay = getCurrentDay();
    
    Serial.println("🔘 Medicine taken button pressed! Time slot: " + currentTimeSlot + " (" + currentDay + ")");
    
    // Mark all medicines for current time slot
    markAllMedicinesForTimeSlot(currentTimeSlot);
    
  } else if (digitalRead(BUTTON_TAKEN_PIN) == HIGH && buttonTakenPressed) {
    buttonTakenPressed = false;
  }
}


// === Medicine Reminder Logic ===
void checkReminder() {
  if (uid.length() == 0) return;
  
  String currentDay = getCurrentDay();
  String currentTimeSlot = getCurrentTimeSlot();
  String currentTime = getTimeString();
  
  for (int i = 0; i < prescriptionCount; i++) {
    // Check if this prescription is for today
    if (prescriptions[i].selectedDays.indexOf(currentDay) == -1) continue;
    
    // Check if it's the right time slot
    if (prescriptions[i].timeSlot != currentTimeSlot) continue;
    
    // Check if it's the right time (with 5 minute tolerance)
    if (isTimeMatch(currentTime, prescriptions[i].time)) {
      int dayIndex = getDayIndex(currentDay);
      int timeSlotIndex = getTimeSlotIndex(currentTimeSlot);
      
      if (!alreadyAlerted[i][dayIndex][timeSlotIndex]) {
        Serial.println("💊 Take medicine: " + prescriptions[i].medicineName + 
                      " @ " + currentTime + " (" + currentTimeSlot + ")");
        
        // Mark as taken in Firestore
        markMedicineTaken(prescriptions[i].id, currentDay, currentTimeSlot);
        
        alreadyAlerted[i][dayIndex][timeSlotIndex] = true;
      }
    }
  }
}

bool isTimeMatch(String currentTime, String medicineTime) {
  int currentHour = currentTime.substring(0, 2).toInt();
  int currentMin = currentTime.substring(3, 5).toInt();
  int medHour = medicineTime.substring(0, 2).toInt();
  int medMin = medicineTime.substring(3, 5).toInt();
  
  int currentTotal = currentHour * 60 + currentMin;
  int medTotal = medHour * 60 + medMin;
  
  return abs(currentTotal - medTotal) <= 5;  // 5 minute tolerance
}

int getDayIndex(String day) {
  if (day == "Monday") return 0;
  if (day == "Tuesday") return 1;
  if (day == "Wednesday") return 2;
  if (day == "Thursday") return 3;
  if (day == "Friday") return 4;
  if (day == "Saturday") return 5;
  if (day == "Sunday") return 6;
  return 0;
}

int getTimeSlotIndex(String timeSlot) {
  if (timeSlot == "Morning") return 0;
  if (timeSlot == "Afternoon") return 1;
  if (timeSlot == "Night") return 2;
  return 0;
}


void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  if (!rtc.begin()) {
    Serial.println("❌ RTC not found!");
    while (1);
  }
  if (rtc.lostPower()) rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));

  // Setup pins
  pinMode(BUTTON_TAKEN_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  deviceID = "ESP_" + String((uint32_t)ESP.getEfuseMac(), HEX);
  
  // Build Firestore URLs
  getDeviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                 "/databases/(default)/documents/" + devicesCollection + "/" + deviceID + "?key=" + API_KEY;
  
  createDeviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                   "/databases/(default)/documents/" + devicesCollection +
                   "?documentId=" + deviceID + "&key=" + API_KEY;
  
  getPrescriptionsURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                       "/databases/(default)/documents:runQuery?key=" + API_KEY;
  
  createMedicineTakenURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                          "/databases/(default)/documents/" + medicineTakenCollection +
                          "?key=" + API_KEY;

  Serial.println("🌐 Connecting to WiFi: " + String(WIFI_SSID));
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500); 
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n✅ Connected! IP: %s\n", WiFi.localIP().toString().c_str());
    handleLoop = true;
    
    // Initialize Firestore connection
    if (checkAndCreateDevice()) {
      if (uid.length() > 0) {
        fetchPrescriptions();
      } else {
        Serial.println("⚠️ Device created but not assigned to user yet");
        Serial.println("📱 Please connect this device in the app to start using it");
      }
    }
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.println("🔧 Please check your WiFi credentials and try again");
    while (1) {
      delay(1000);
      Serial.println("🔄 Restarting in 5 seconds...");
      delay(5000);
      ESP.restart();
    }
  }

  // Initialize alert tracking
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 7; j++) {
      for (int k = 0; k < 3; k++) {
        alreadyAlerted[i][j][k] = false;
      }
    }
  }
  
  Serial.println("🔘 Button pin: Taken=" + String(BUTTON_TAKEN_PIN));
  Serial.println("📡 Internet functionality enabled");
  Serial.println("🆔 Device ID: " + deviceID);
}

void loop() {
  if (handleLoop) {
    static unsigned long lastCheck = 0;
    if (millis() - lastCheck > 30000) {  // Check every 30 seconds
      lastCheck = millis();
      if (uid.length() > 0) {
        Serial.println("🔄 Auto-refreshing prescriptions...");
        fetchPrescriptions();  // Refresh prescriptions every 30 seconds
      }
    }
    
    // Check for button presses
    checkButtons();
    
    // Check for automatic reminders
    checkReminder();
  }
}
