#include <Adafruit_NeoPixel.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    29
#define BRIGHTNESS  40
#define NUM_SLICES  36  

Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// The Polar Image Buffer: [Angle/Slice][Radius/LED Index]
uint32_t image_buffer[NUM_SLICES][NUM_LEDS];

// Volatile variables modified inside the ISR
volatile unsigned long t0 = 0;       
volatile unsigned long period = 0;   
volatile bool new_rotation = false;

// Optimization tracker to prevent redundant strip.show() calls
int last_slice = -1;

// --- BLE CONFIGURATION ---
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected.");
    }
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected.");
      BLEDevice::startAdvertising(); // restart advertising
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();
      
      // We expect 88 bytes: 1 byte for slice index + 87 bytes for RGB colors (29 * 3)
      if (rxValue.length() == 88) {
        uint8_t slice = rxValue[0];
        if (slice < NUM_SLICES) {
          int offset = 1;
          for (int i = 0; i < NUM_LEDS; i++) {
             uint8_t r = rxValue[offset++];
             uint8_t g = rxValue[offset++];
             uint8_t b = rxValue[offset++];
             image_buffer[slice][i] = strip.Color(r, g, b);
          }
        }
      } else {
        Serial.print("Received incorrect data length: ");
        Serial.println(rxValue.length());
      }
    }
};

void IRAM_ATTR hall_isr() {
  unsigned long now = micros(); 
  period = now - t0;                 
  t0 = now;                          
  new_rotation = true;
}

void setup() {
  Serial.begin(115200);

  pinMode(HALL_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(HALL_PIN), hall_isr, RISING);

  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  strip.clear();
  strip.show();

  // Clear image_buffer
  for(int s=0; s<NUM_SLICES; s++) {
    for(int l=0; l<NUM_LEDS; l++) {
      image_buffer[s][l] = strip.Color(0,0,0);
    }
  }

  // --- Initialize BLE ---
  BLEDevice::init("POV Display");
  
  // Request a larger MTU so we can receive 88 byte packets without fragmentation
  BLEDevice::setMTU(512); 
  
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_WRITE | 
                                         BLECharacteristic::PROPERTY_WRITE_NR
                                       );

  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("BLE Setup Complete. Advertising as 'POV Display'...");
}

void loop() {
  unsigned long current_time = micros(); 
  
  noInterrupts();
  unsigned long current_t0 = t0;
  unsigned long current_period = period;
  bool local_new_rotation = new_rotation;
  new_rotation = false; 
  interrupts();

  if (current_period == 0) return; 

  unsigned long elapsed = current_time - current_t0;

  // Shut down LEDs if the motor stops (elapsed time exceeds one full rotation period)
  if (elapsed >= current_period) {
    if (last_slice != -1) { // Only clear once
      strip.clear();
      strip.show();
      last_slice = -1;
    }
    return;
  }

  // Determine current slice (0 to 35)
  uint8_t current_slice = (elapsed * NUM_SLICES) / current_period;

  // Only update the LEDs if we have moved into a new physical slice
  if (current_slice < NUM_SLICES && current_slice != last_slice) {
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, image_buffer[current_slice][i]);
    }
    strip.show();
    last_slice = current_slice; 
  }
}
