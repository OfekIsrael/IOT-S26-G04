#include <Adafruit_NeoPixel.h>
#include "ota.h"

// Hardware definitions
#define LED_PIN     13
#define HALL_PIN    15
#define NUM_LEDS    116

// Safe brightness limit to prevent ESP32 power crashes
#define BRIGHTNESS  40

// Initialize the Adafruit NeoPixel object
Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Volatile flag to safely communicate between the Interrupt and the main loop
volatile bool trigger_detected = false;

// Interrupt Service Routine (ISR)
void IRAM_ATTR hall_isr() {
  trigger_detected = true;
}

void setup() {
  ota::begin();
  // Initialize the Hall sensor pin
  pinMode(HALL_PIN, INPUT_PULLUP);
  
  // Attach the interrupt to trigger specifically on a RISING edge
  attachInterrupt(digitalPinToInterrupt(HALL_PIN), hall_isr, RISING);

  // Initialize the Adafruit strip
  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  
  // Ensure LEDs start completely off
  strip.clear();
  strip.show();
}

void loop() {
  ota::update();
  if (trigger_detected) {
    // 1. Turn all LEDs ON (Solid Green)
    // strip.Color takes RGB values (Red, Green, Blue) from 0-255
    strip.fill(strip.Color(0, 255, 0));
    strip.show();

    // 2. Keep the LEDs on for a short period (50 milliseconds)
    delay(5);

    // 3. Turn all LEDs OFF
    strip.clear();
    strip.show();

    // 4. Reset the trigger flag AFTER the delay. 
    // This ignores any extra sensor noise that happened during the flash.
    trigger_detected = false;
  }
}