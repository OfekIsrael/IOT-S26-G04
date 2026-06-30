#include <Adafruit_NeoPixel.h>
#include "ota.h"

#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    116
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
  pinMode(HALL_PIN, INPUT_PULLUP);
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

  // If we are within the first quarter of the spin (T0 to T0 + T/4)
  if (current_time - current_t0 < (current_period / 4)) {
    strip.fill(strip.Color(0, 255, 0)); // Green
    strip.show();
  } else {
    strip.clear();
    strip.show();
  }
}