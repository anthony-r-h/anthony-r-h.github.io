#include <Wire.h>
#include <Adafruit_NAU7802.h>
#include <TFT_eSPI.h>

// T-QT Pro Qwiic/STEMMA starting point.
// Confirm with tqtpro_i2c_scanner.ino before using this sketch.
constexpr int I2C_SDA = 43;
constexpr int I2C_SCL = 44;

// External prototype button. Wire switch from this GPIO to GND.
// Change this pin to one that is actually free on your board.
constexpr int TARE_PIN = 14;

// Placeholder until calibration.
// After calibration, countsPerNm = (raw_at_known_torque - raw_zero) / known_torque_Nm.
float countsPerNm = 10000.0f;
float targetNm = 10.0f;

Adafruit_NAU7802 nau;
TFT_eSPI tft = TFT_eSPI();

int32_t zeroOffset = 0;
float peakNm = 0.0f;

int32_t readAverage(uint8_t samples) {
  int64_t sum = 0;
  for (uint8_t i = 0; i < samples; i++) {
    while (!nau.available()) {
      delay(1);
    }
    sum += nau.read();
  }
  return (int32_t)(sum / samples);
}

void tareNow() {
  zeroOffset = readAverage(16);
  peakNm = 0.0f;
  Serial.print("Tare raw offset = ");
  Serial.println(zeroOffset);
}

void drawTorque(float torqueNm, int32_t raw) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);

  tft.setTextDatum(TL_DATUM);
  tft.setTextSize(2);
  tft.setCursor(6, 8);
  tft.print(torqueNm, 1);
  tft.print(" Nm");

  tft.setTextSize(1);
  tft.setCursor(6, 45);
  tft.print("Peak ");
  tft.print(peakNm, 1);

  tft.setCursor(6, 62);
  tft.print("Target ");
  tft.print(targetNm, 1);

  tft.setCursor(6, 82);
  tft.print("Raw ");
  tft.print(raw);
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(TARE_PIN, INPUT_PULLUP);

  tft.init();
  tft.setRotation(0);
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(1);
  tft.setCursor(0, 0);
  tft.println("Torque adapter");

  Wire.begin(I2C_SDA, I2C_SCL);

  if (!nau.begin()) {
    Serial.println("NAU7802 not found. Run scanner and check SDA/SCL.");
    tft.println("NAU7802 not found");
    while (true) delay(10);
  }

  nau.setLDO(NAU7802_3V0);
  nau.setGain(NAU7802_GAIN_128);
  nau.setRate(NAU7802_RATE_80SPS);

  for (uint8_t i = 0; i < 10; i++) {
    while (!nau.available()) delay(1);
    nau.read();
  }

  while (!nau.calibrate(NAU7802_CALMOD_INTERNAL)) {
    Serial.println("Retrying internal calibration");
    delay(500);
  }

  while (!nau.calibrate(NAU7802_CALMOD_OFFSET)) {
    Serial.println("Retrying offset calibration");
    delay(500);
  }

  tareNow();
}

void loop() {
  static uint32_t lastDrawMs = 0;
  static bool lastTareState = HIGH;

  bool tareState = digitalRead(TARE_PIN);
  if (lastTareState == HIGH && tareState == LOW) {
    tareNow();
  }
  lastTareState = tareState;

  int32_t raw = readAverage(4);
  float torqueNm = (raw - zeroOffset) / countsPerNm;

  if (torqueNm > peakNm) peakNm = torqueNm;

  Serial.print("raw=");
  Serial.print(raw);
  Serial.print(" torque_Nm=");
  Serial.print(torqueNm, 3);
  Serial.print(" peak_Nm=");
  Serial.println(peakNm, 3);

  if (millis() - lastDrawMs > 150) {
    drawTorque(torqueNm, raw);
    lastDrawMs = millis();
  }
}
