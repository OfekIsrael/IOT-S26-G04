#define HALL_PIN 15

void setup() {
  Serial.begin(115200);
  pinMode(HALL_PIN, INPUT_PULLUP);
  Serial.println("Hall Sensor Test Started");
  Serial.println("Bring a magnet close to the sensor...");
}

void loop() {
  int sensorValue = digitalRead(HALL_PIN);
  
  if (sensorValue == LOW) {
    Serial.println("Magnet DETECTED!");
  } else {
    Serial.println("No magnet.");
  }
  
  delay(100);
}
