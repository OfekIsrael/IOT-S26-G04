#include <Adafruit_NeoPixel.h>
#include "ota.h"

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    29
#define BRIGHTNESS  40

Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Volatile variables modified inside the ISR
volatile unsigned long t0 = 0;       // Start time of current rotation (ms)
volatile unsigned long period = 0;   // Duration of the last full rotation (ms)
volatile bool new_rotation = false;

void IRAM_ATTR hall_isr() {
  unsigned long now = millis();
  period = now - t0;                 // Calculate T based on the last trigger
  t0 = now;                          // Reset T0 for the new rotation
  new_rotation = true;
}

void setup() {
  pinMode(HALL_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(HALL_PIN), hall_isr, RISING);

  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  strip.clear();
  strip.show();
}

void loop() {
  unsigned long current_time = millis();
  
  // Local copies of volatile variables to ensure atomic math
  noInterrupts();
  unsigned long current_t0 = t0;
  unsigned long current_period = period;
  interrupts();

  // Slice 1: Red (Original)
  if (current_time - current_t0 < (current_period / 12)) {
    strip.fill(strip.Color(255, 0, 0)); 
    strip.show();
  } 
  // Slice 2: Yellow (Original)
  else if (current_time - current_t0 >= (current_period / 12) && current_time - current_t0 < 2 * (current_period / 12)) {
    strip.fill(strip.Color(255, 255, 0)); 
    strip.show();
  } 
  // Slice 3: Green (Original)
  else if (current_time - current_t0 >= 2 * (current_period / 12) && current_time - current_t0 < 3 * (current_period / 12)) {
    strip.fill(strip.Color(0, 255, 0)); 
    strip.show();
  } 
  // Slice 4: Cyan (Original)
  else if (current_time - current_t0 >= 3 * (current_period / 12) && current_time - current_t0 < 4 * (current_period / 12)) {
    strip.fill(strip.Color(0, 255, 255)); 
    strip.show();
  } 
  // Slice 5: Blue (Original)
  else if (current_time - current_t0 >= 4 * (current_period / 12) && current_time - current_t0 < 5 * (current_period / 12)) {
    strip.fill(strip.Color(0, 0, 255)); 
    strip.show();
  } 
  // Slice 6: Magenta (Original)
  else if (current_time - current_t0 >= 5 * (current_period / 12) && current_time - current_t0 < 6 * (current_period / 12)) {
    strip.fill(strip.Color(255, 0, 255)); 
    strip.show();
  } 
  // Slice 7: Brown (New)
  else if (current_time - current_t0 >= 6 * (current_period / 12) && current_time - current_t0 < 7 * (current_period / 12)) {
    strip.fill(strip.Color(150, 75, 0)); 
    strip.show();
  } 
  // Slice 8: White (New)
  else if (current_time - current_t0 >= 7 * (current_period / 12) && current_time - current_t0 < 8 * (current_period / 12)) {
    strip.fill(strip.Color(255, 255, 255)); 
    strip.show();
  } 
  // Slice 9: Gold (New)
  else if (current_time - current_t0 >= 8 * (current_period / 12) && current_time - current_t0 < 9 * (current_period / 12)) {
    strip.fill(strip.Color(255, 180, 0)); 
    strip.show();
  } 
  // Slice 10: Teal (New)
  else if (current_time - current_t0 >= 9 * (current_period / 12) && current_time - current_t0 < 10 * (current_period / 12)) {
    strip.fill(strip.Color(0, 128, 128)); 
    strip.show();
  } 
  // Slice 11: Indigo (New)
  else if (current_time - current_t0 >= 10 * (current_period / 12) && current_time - current_t0 < 11 * (current_period / 12)) {
    strip.fill(strip.Color(75, 0, 130)); 
    strip.show();
  } 
  // Slice 12: Crimson (New)
  else if (current_time - current_t0 >= 11 * (current_period / 12) && current_time - current_t0 < 12 * (current_period / 12)) {
    strip.fill(strip.Color(220, 20, 60)); 
    strip.show();
  } 
  // Default (Off for the remainder of the rotation if there's a slight timing overflow, or if stopped)
  else {
    strip.clear();
    strip.show();
  }
}