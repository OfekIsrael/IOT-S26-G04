#include <Adafruit_NeoPixel.h>
#include "ota.h"

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    29
#define BRIGHTNESS  40
#define NUM_SLICES  36  // Updated to 36 slices

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
  // Changed to micros() for higher resolution timing
  unsigned long now = micros(); 
  period = now - t0;                 
  t0 = now;                          
  new_rotation = true;
}

// Function to populate a 36-slice pattern with repeating colors
void generateTestPattern() {
  // 1. Define the 6 repeating colors (Red, Green, Blue, Yellow, Cyan, Magenta)
  uint32_t colors[6] = {
    strip.Color(255, 0, 0),   // Red
    strip.Color(0, 255, 0),   // Green
    strip.Color(0, 0, 255),   // Blue
    strip.Color(255, 255, 0), // Yellow
    strip.Color(0, 255, 255), // Cyan
    strip.Color(255, 0, 255)  // Magenta
  };

  // 2. Loop through all 36 slices
  for (int s = 0; s < NUM_SLICES; s++) {
    // Select the color for the current slice by looping through the 6 colors
    uint32_t current_color = colors[s % 6]; 
    
    // 3. Fill the entire length of the LED strip for this slice with the chosen color
    for (int i = 0; i < NUM_LEDS; i++) {
      image_buffer[s][i] = current_color;
    }
  }
}

void setup() {
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
  // Changed to micros() to match the ISR
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
  // Mathematical note: elapsed * NUM_SLICES fits safely inside a 32-bit unsigned long 
  // as long as the period is less than ~119 seconds (well within POV speeds).
  uint8_t current_slice = (elapsed * NUM_SLICES) / current_period;

  // Only update the LEDs if we have moved into a new physical slice
  if (current_slice < NUM_SLICES && current_slice != last_slice) {
    
    // Map the pre-calculated array slice to the physical LEDs
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, image_buffer[current_slice][i]);
    }
    
    strip.show();
    last_slice = current_slice; // Record that this slice is currently being displayed
  }
}