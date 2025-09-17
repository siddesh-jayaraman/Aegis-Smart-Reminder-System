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
String collectionName = "medicine_schedule";
String getDocURL, createDocURL, commitURL;


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
String medicineTimes[15];
bool alreadyAlerted[15];


// === Firestore helpers ===
void createInitialDoc() {
  HTTPClient http;
  http.begin(createDocURL);
  http.addHeader("Content-Type", "application/json");
  StaticJsonDocument<256> doc;
  auto f = doc.createNestedObject("fields");
  f["DID"]["stringValue"] = deviceID;
  f["data"]["stringValue"] = "08:00,12:00,18:00,08:10,12:10,18:10,08:20,12:20,18:20,08:30,12:30,18:30,08:40,12:40,18:40";
  f["update"]["integerValue"] = 0;
  String body; serializeJson(doc, body);
  int code = http.POST(body);
  http.end();
  Serial.printf(code == 200 ? "✅ Doc created\n" : "❌ Doc create failed\n");
}


void ensureDocExists() {
  HTTPClient http;
  http.begin(getDocURL);
  int code = http.GET();
  http.end();
  if (code == 404) createInitialDoc();
}


void fetchScheduleIfUpdated() {
  HTTPClient http;
  http.begin(getDocURL);
  int code = http.GET();
  if (code == 200) {
    String payload = http.getString();
    StaticJsonDocument<1024> doc;
    deserializeJson(doc, payload);
    String updateVal = doc["fields"]["update"]["integerValue"];
    if (updateVal == "1") {
      String data = doc["fields"]["data"]["stringValue"];
      int index = 0;
      while (data.length() > 0 && index < 15) {
        int commaIndex = data.indexOf(',');
        if (commaIndex != -1) {
          medicineTimes[index++] = data.substring(0, commaIndex);
          data = data.substring(commaIndex + 1);
        } else {
          medicineTimes[index++] = data;
          break;
        }
      }
      HTTPClient put;
      put.begin(commitURL);
      put.addHeader("Content-Type", "application/json");
      StaticJsonDocument<256> updateDoc;
      auto writes = updateDoc.createNestedArray("writes");
      auto w = writes.createNestedObject();
      auto update = w.createNestedObject("update");
      update["name"] = "projects/" + projectId + "/databases/(default)/documents/" + collectionName + "/" + deviceID;
      update["fields"]["update"]["integerValue"] = 0;
      String jsonStr; serializeJson(updateDoc, jsonStr);
      put.POST(jsonStr);
      put.end();
    }
  }
  http.end();
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


// === Reminder Logic ===
void checkReminder() {
  DateTime now = rtc.now();
  int dayIndex = now.dayOfTheWeek() - 1; // Mon = 0
  if (dayIndex < 0 || dayIndex > 4) return;


  char buf[6];
  sprintf(buf, "%02d:%02d", now.hour(), now.minute());
  String currentTime = String(buf);


  for (int slot = 0; slot < 3; slot++) {
    int idx = (dayIndex * 3) + slot;
    if (medicineTimes[idx] == currentTime && !alreadyAlerted[idx]) {
      Serial.printf("💊 Take medicine: Day %d - Slot %d @ %s\n", dayIndex, slot, buf);
      alreadyAlerted[idx] = true;
    } else if (medicineTimes[idx] != currentTime) {
      alreadyAlerted[idx] = false;
    }
  }
}


void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  if (!rtc.begin()) {
    Serial.println("❌ RTC not found!");
    while (1);
  }
  if (rtc.lostPower()) rtc.adjust(DateTime(F(_DATE), F(TIME_)));


  EEPROM.begin(EEPROM_SIZE);
  int slen = EEPROM.read(ADDR_SSID_LEN);
  String ssid = "", pass = "";
  if (slen > 0 && slen <= EEPROM_MAX_SSID_LEN)
    for (int i = 0; i < slen; i++) ssid += char(EEPROM.read(SSID_ADDR + i));
  int plen = EEPROM.read(ADDR_PASS_LEN);
  if (plen > 0 && plen <= EEPROM_MAX_PASS_LEN)
    for (int i = 0; i < plen; i++) pass += char(EEPROM.read(PASS_ADDR + i));


  deviceID = "ESP_" + String((uint32_t)ESP.getEfuseMac(), HEX);
  getDocURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
              "/databases/(default)/documents/" + collectionName + "/" + deviceID + "?key=" + API_KEY;
  createDocURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                 "/databases/(default)/documents/" + collectionName +
                 "?documentId=" + deviceID + "&key=" + API_KEY;
  commitURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
              "/databases/(default)/documents:commit?key=" + API_KEY;


  if (ssid.length()) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    while (WiFi.status() != WL_CONNECTED) {
      delay(500); Serial.print(".");
    }
    Serial.printf("\nConnected! IP: %s\n", WiFi.localIP().toString().c_str());
    handleLoop = true;
    ensureDocExists();
    fetchScheduleIfUpdated();
  } else {
    WiFi.softAP("ESP32-Reminder", "12345678");
    Serial.println("AP mode. Connect to: ESP32-Reminder");
    server.on("/", handleRoot);
    server.on("/save", handleSave);
    server.begin();
  }


  for (int i = 0; i < 15; i++) {
    medicineTimes[i] = "00:00";
    alreadyAlerted[i] = false;
  }
}


void loop() {
  server.handleClient();
  if (handleLoop) {
    static unsigned long lastCheck = 0;
    if (millis() - lastCheck > 60000) {
      lastCheck = millis();
      fetchScheduleIfUpdated();
    }
    checkReminder();
  }
}