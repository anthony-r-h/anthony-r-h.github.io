#include <Wire.h>

// T-QT Pro Qwiic/STEMMA starting point.
// Run this first. If no 0x2A device appears, swap SDA/SCL or check wiring.
constexpr int I2C_SDA = 43;
constexpr int I2C_SCL = 44;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Wire.begin(I2C_SDA, I2C_SCL);
  Serial.println("I2C scanner started");
  Serial.println("Expected NAU7802 address: 0x2A");
}

void loop() {
  int found = 0;

  for (uint8_t address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    uint8_t error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("Found I2C device at 0x");
      if (address < 16) Serial.print("0");
      Serial.println(address, HEX);
      found++;
    }
  }

  if (found == 0) {
    Serial.println("No I2C devices found");
  }

  Serial.println("---");
  delay(2000);
}
