#include <Adafruit_NeoPixel.h>
#include "ota.h"

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    29
#define BRIGHTNESS  40
#define NUM_SLICES  20

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

// Function to populate our 20-slice hardcoded square
void generateTestPattern() {
  // 1. Clear buffer to black
  for (int s = 0; s < NUM_SLICES; s++) {
    for (int i = 0; i < NUM_LEDS; i++) {
      image_buffer[s][i] = strip.Color(0, 0, 0);
    }
  }

  // 2. Lookup Table for a perfect square across 20 slices (18 degrees per slice)
  // These are the physical LED indices (calculated via Trigonometry)
  // 10 = Flat sides, 9 = Mid-points, 6 = Corners
  const int square_indices[20] = {
    10, 9, 6, 6, 9,   // Slices 0 to 4   (0 to 72 deg)
    10, 9, 6, 6, 9,   // Slices 5 to 9   (90 to 162 deg)
    10, 9, 6, 6, 9,   // Slices 10 to 14 (180 to 252 deg)
    10, 9, 6, 6, 9    // Slices 15 to 19 (270 to 342 deg)
  };

  // 3. Draw the square (3 pixels thick)
  for (int s = 0; s < NUM_SLICES; s++) {
    int center_idx = square_indices[s];
    
    // Choose color: Green for the flatter sides, Yellow for the stretched corners
    uint32_t color;
    if (center_idx == 6) {
      color = strip.Color(255, 255, 0); // Yellow corners
    } else {
      color = strip.Color(0, 255, 0);   // Green sides
    }

    // Apply the 3-pixel thickness around our calculated center point
    for (int offset = -1; offset <= 1; offset++) {
      int idx = center_idx + offset;
      // Safety check to ensure we don't write outside the LED array bounds
      if (idx >= 0 && idx < NUM_LEDS) {
        image_buffer[s][idx] = color;
      }
    }
  }

  // 4. A single Blue dot at the exact center (LED 28) for a visual anchor point
  for (int s = 0; s < NUM_SLICES; s++) {
    image_buffer[s][28] = strip.Color(0, 0, 255);
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