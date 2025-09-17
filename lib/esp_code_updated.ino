#include <WiFi.h>
#include <WebServer.h>
#include <EEPROM.h>
#include <Wire.h>
#include <RTClib.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>

// Firestore Info
const char* API_KEY = "AIzaSyDjXZJU7xgMDqE8h_FlcxR-8kjtQpE73FE";
String projectId = "streamcamera-a78e7";

// Collections
String devicesCollection = "devices";
String prescriptionsCollection = "prescriptions";
String medicineTakenCollection = "medicine_taken";

// URLs
String getDeviceURL, getPrescriptionsURL, createMedicineTakenURL;

#define EEPROM_SIZE           512
#define ADDR_SSID_LEN         1
#define SSID_ADDR             2
#define EEPROM_MAX_SSID_LEN   32
#define ADDR_PASS_LEN         (SSID_ADDR + EEPROM_MAX_SSID_LEN)
#define PASS_ADDR             (ADDR_PASS_LEN + 1)
#define EEPROM_MAX_PASS_LEN   64

WebServer server(80);
RTC_DS3231 rtc;

bool handleLoop = false;
String deviceID;
String uid = "";  // Will be fetched from devices collection

// Medicine tracking
struct Prescription {
  String id;
  String medicineName;
  String time;
  String timeSlot;
  String selectedDays;
  int doseQuantity;
};

Prescription prescriptions[20];  // Max 20 prescriptions
int prescriptionCount = 0;
bool alreadyAlerted[20][7][3];  // [prescription][day][timeSlot] - 7 days, 3 time slots

// === Firestore helpers ===
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

// Fetch UID from devices collection
bool fetchUID() {
  HTTPClient http;
  http.begin(getDeviceURL);
  int code = http.GET();
  
  if (code == 200) {
    String payload = http.getString();
    StaticJsonDocument<1024> doc;
    deserializeJson(doc, payload);
    
    if (doc["fields"]["uid"]["stringValue"]) {
      uid = doc["fields"]["uid"]["stringValue"].as<String>();
      Serial.println("✅ UID fetched: " + uid);
      http.end();
      return true;
    }
  }
  
  Serial.println("❌ Failed to fetch UID");
  http.end();
  return false;
}

// Fetch prescriptions for this device
bool fetchPrescriptions() {
  HTTPClient http;
  http.begin(getPrescriptionsURL);
  int code = http.GET();
  
  if (code == 200) {
    String payload = http.getString();
    StaticJsonDocument<2048> doc;
    deserializeJson(doc, payload);
    
    prescriptionCount = 0;
    
    // Parse prescriptions from Firestore response
    if (doc["documents"]) {
      JsonArray documents = doc["documents"];
      for (JsonObject document : documents) {
        if (prescriptionCount >= 20) break;
        
        JsonObject fields = document["fields"];
        prescriptions[prescriptionCount].id = document["name"].as<String>();
        prescriptions[prescriptionCount].medicineName = fields["medicineName"]["stringValue"].as<String>();
        prescriptions[prescriptionCount].time = fields["time"]["stringValue"].as<String>();
        prescriptions[prescriptionCount].timeSlot = fields["timeSlot"]["stringValue"].as<String>();
        prescriptions[prescriptionCount].doseQuantity = fields["doseQuantity"]["integerValue"].as<int>();
        
        // Parse selected days array
        String selectedDays = "";
        if (fields["selectedDays"]["arrayValue"]["values"]) {
          JsonArray days = fields["selectedDays"]["arrayValue"]["values"];
          for (JsonVariant day : days) {
            if (selectedDays.length() > 0) selectedDays += ",";
            selectedDays += day["stringValue"].as<String>();
          }
        }
        prescriptions[prescriptionCount].selectedDays = selectedDays;
        
        prescriptionCount++;
      }
    }
    
    Serial.println("✅ Fetched " + String(prescriptionCount) + " prescriptions");
    http.end();
    return true;
  }
  
  Serial.println("❌ Failed to fetch prescriptions");
  http.end();
  return false;
}

// Mark medicine as taken
void markMedicineTaken(String prescriptionId, String day, String timeSlot) {
  HTTPClient http;
  http.begin(createMedicineTakenURL);
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
  
  // Current timestamp
  String timestamp = String(rtc.now().unixtime()) + "000000";  // Convert to microseconds
  fields["takenAt"]["timestampValue"] = timestamp;
  
  String body;
  serializeJson(doc, body);
  
  int code = http.POST(body);
  if (code == 200) {
    Serial.println("✅ Medicine marked as taken: " + prescriptionId);
  } else {
    Serial.println("❌ Failed to mark medicine taken: " + String(code));
  }
  
  http.end();
}

// Check if medicine should be taken now
void checkReminder() {
  if (uid.length() == 0) return;
  
  DateTime now = rtc.now();
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
      // Check if already alerted for this prescription today
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

// Helper function to check if times match (with 5 minute tolerance)
bool isTimeMatch(String currentTime, String medicineTime) {
  int currentHour = currentTime.substring(0, 2).toInt();
  int currentMin = currentTime.substring(3, 5).toInt();
  int medHour = medicineTime.substring(0, 2).toInt();
  int medMin = medicineTime.substring(3, 5).toInt();
  
  int currentTotal = currentHour * 60 + currentMin;
  int medTotal = medHour * 60 + medMin;
  
  return abs(currentTotal - medTotal) <= 5;  // 5 minute tolerance
}

// Helper function to get day index
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

// Helper function to get time slot index
int getTimeSlotIndex(String timeSlot) {
  if (timeSlot == "Morning") return 0;
  if (timeSlot == "Afternoon") return 1;
  if (timeSlot == "Night") return 2;
  return 0;
}

// === EEPROM & Portal ===
const char htmlPage[] PROGMEM = R"rawliteral(
<!DOCTYPE html><html><body>
<h2>WiFi Setup</h2>
<form action="/save">
SSID:<br><input name="ssid"><br>
Password:<br><input name="pass" type="password"><br>
<input type="submit" value="Connect">
</form></body></html>)rawliteral";

void handleRoot() {
  server.send_P(200, "text/html", htmlPage);
}

void handleSave() {
  String ssid = server.arg("ssid");
  String pass = server.arg("pass");
  EEPROM.write(ADDR_SSID_LEN, ssid.length());
  for (int i = 0; i < EEPROM_MAX_SSID_LEN; i++)
    EEPROM.write(SSID_ADDR + i, i < ssid.length() ? ssid[i] : 0);
  EEPROM.write(ADDR_PASS_LEN, pass.length());
  for (int i = 0; i < EEPROM_MAX_PASS_LEN; i++)
    EEPROM.write(PASS_ADDR + i, i < pass.length() ? pass[i] : 0);
  EEPROM.commit();
  server.send(200, "text/plain", "Saved. Restarting...");
  delay(2000);
  ESP.restart();
}

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  if (!rtc.begin()) {
    Serial.println("❌ RTC not found!");
    while (1);
  }
  if (rtc.lostPower()) rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));

  EEPROM.begin(EEPROM_SIZE);
  int slen = EEPROM.read(ADDR_SSID_LEN);
  String ssid = "", pass = "";
  if (slen > 0 && slen <= EEPROM_MAX_SSID_LEN)
    for (int i = 0; i < slen; i++) ssid += char(EEPROM.read(SSID_ADDR + i));
  int plen = EEPROM.read(ADDR_PASS_LEN);
  if (plen > 0 && plen <= EEPROM_MAX_PASS_LEN)
    for (int i = 0; i < plen; i++) pass += char(EEPROM.read(PASS_ADDR + i));

  deviceID = "ESP_" + String((uint32_t)ESP.getEfuseMac(), HEX);
  
  // Build Firestore URLs
  getDeviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                 "/databases/(default)/documents/" + devicesCollection + "/" + deviceID + "?key=" + API_KEY;
  
  getPrescriptionsURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                       "/databases/(default)/documents?collectionId=" + prescriptionsCollection +
                       "&key=" + API_KEY;
  
  createMedicineTakenURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                          "/databases/(default)/documents/" + medicineTakenCollection +
                          "?documentId=" + String(millis()) + "&key=" + API_KEY;

  if (ssid.length()) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    while (WiFi.status() != WL_CONNECTED) {
      delay(500); Serial.print(".");
    }
    Serial.printf("\nConnected! IP: %s\n", WiFi.localIP().toString().c_str());
    handleLoop = true;
    
    // Initialize Firestore connection
    if (fetchUID()) {
      fetchPrescriptions();
    }
  } else {
    WiFi.softAP("ESP32-Reminder", "12345678");
    Serial.println("AP mode. Connect to: ESP32-Reminder");
    server.on("/", handleRoot);
    server.on("/save", handleSave);
    server.begin();
  }

  // Initialize alert tracking
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 7; j++) {
      for (int k = 0; k < 3; k++) {
        alreadyAlerted[i][j][k] = false;
      }
    }
  }
}

void loop() {
  server.handleClient();
  if (handleLoop) {
    static unsigned long lastCheck = 0;
    if (millis() - lastCheck > 300000) {  // Check every 5 minutes
      lastCheck = millis();
      if (uid.length() > 0) {
        fetchPrescriptions();  // Refresh prescriptions periodically
      }
    }
    checkReminder();
  }
}
