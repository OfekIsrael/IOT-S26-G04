#include <Adafruit_NeoPixel.h>
#include "ota.h"

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    29
#define BRIGHTNESS  40
#define NUM_SLICES  12

Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// The Polar Image Buffer: [Angle/Slice][Radius/LED Index]
uint32_t image_buffer[NUM_SLICES][NUM_LEDS];

// Volatile variables modified inside the ISR
volatile unsigned long t0 = 0;       
volatile unsigned long period = 0;   
volatile bool new_rotation = false;

// Optimization tracker to prevent redundant strip.show() calls
int last_slice = -1;

void IRAM_ATTR hall_isr() {
  unsigned long now = millis();
  period = now - t0;                 
  t0 = now;                          
  new_rotation = true;
}

// Function to populate our 12-slice Smiley Face
void generateTestPattern() {
  // 1. Clear the entire buffer to black first
  for (int s = 0; s < NUM_SLICES; s++) {
    for (int i = 0; i < NUM_LEDS; i++) {
      image_buffer[s][i] = strip.Color(0, 0, 0);
    }
  }

  // 2. Draw the solid Yellow Face Base
  // Center is 28. We draw outward to index 6 (leaving a tiny black gap at the edge)
  for (int s = 0; s < NUM_SLICES; s++) {
    for (int i = 6; i <= 28; i++) {
      image_buffer[s][i] = strip.Color(255, 255, 0); // Solid Yellow
    }
  }

  // 3. Draw the Eyes (Punching out Black pixels)
  // Slice 10 is Top-Left (300 deg), Slice 2 is Top-Right (60 deg)
  for (int i = 16; i <= 19; i++) {
    image_buffer[10][i] = strip.Color(0, 0, 0); // Left Eye
    image_buffer[2][i]  = strip.Color(0, 0, 0); // Right Eye
  }

  // 4. Draw the Smile (Punching out Black pixels to form a U-curve)
  // The smile spans from Slice 4 (Left cheek) across the bottom (Slice 6) to Slice 8 (Right cheek)
  
  // Outer corners of the smile (Closer to center, Radius ~13 LEDs)
  for (int i = 14; i <= 16; i++) {
    image_buffer[8][i] = strip.Color(255, 0, 0); 
    image_buffer[4][i] = strip.Color(255, 0, 0);
    image_buffer[7][i] = strip.Color(255, 0, 0);
    image_buffer[5][i] = strip.Color(255, 0, 0);
    image_buffer[6][i] = strip.Color(255, 0, 0);
  }
}

void setup() {
  ota::begin();
  ota::webPrintln("Polar Matrix Test Booted.");

  pinMode(HALL_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(HALL_PIN), hall_isr, RISING);

  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  strip.clear();
  strip.show();

  // Load the test pattern into the matrix buffer
  generateTestPattern();
}

void loop() {
  ota::update();

  unsigned long current_time = millis();
  
  noInterrupts();
  unsigned long current_t0 = t0;
  unsigned long current_period = period;
  bool local_new_rotation = new_rotation;
  new_rotation = false; 
  interrupts();

  if (local_new_rotation && current_period > 0) {
    ota::webPrintln("Period: " + String(current_period) + " ms");
  }

  if (current_period == 0) return; 

  unsigned long elapsed = current_time - current_t0;

  // Shut down LEDs if the motor stops
  if (elapsed >= current_period) {
    if (last_slice != -1) { // Only clear once
      strip.clear();
      strip.show();
      last_slice = -1;
    }
    return;
  }

  // Determine current slice (0 to 11)
  uint8_t current_slice = (elapsed * NUM_SLICES) / current_period;

  // Only update the LEDs if we have moved into a new slice
  if (current_slice < NUM_SLICES && current_slice != last_slice) {
    
    // Map the pre-calculated array slice to the physical LEDs
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, image_buffer[current_slice][i]);
    }
    
    strip.show();
    last_slice = current_slice; // Record that this slice is currently being displayed
  }
}