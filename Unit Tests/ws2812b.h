#pragma once

#include "matrix.h"
#include "array.h"
#include "globals.h"
#include <Adafruit_NeoPixel.h>

namespace ws2812b {

namespace {
// Initialize the strip with the full 116 physical LEDs
Adafruit_NeoPixel _strip(globals::PHYSICAL_LED_COUNT, globals::PIN_NUMBER_OF_LED_STRIP_1, NEO_GRB + NEO_KHZ800);
}

void begin() {
  _strip.begin();  
  _strip.clear();
  Serial.println("ws2812b initialized for zig-zag topology.");
}

Array<uint32_t, globals::NUMBER_OF_LEDS_IN_LED_STRIP_1> convert_rgb_to_neopixel_rgb(const Matrix<uint8_t, globals::NUMBER_OF_LEDS_IN_LED_STRIP_1, 3>& v) {
  Array<uint32_t, globals::NUMBER_OF_LEDS_IN_LED_STRIP_1> res;
  for (int i = 0; i < globals::NUMBER_OF_LEDS_IN_LED_STRIP_1; i++) {
    res.at(i) = _strip.Color(v.at(i, 0), v.at(i, 1), v.at(i, 2));
  }
  return res;
}

void update_LED(const Array<uint32_t, globals::NUMBER_OF_LEDS_IN_LED_STRIP_1>& v) {
  for (int r = 0; r < globals::NUMBER_OF_LEDS_IN_LED_STRIP_1; r++) {
    // Strip 1: LED 0=edge → LED 57=other edge
    _strip.setPixelColor(r, v.at(r));

    // Strip 2: LED 58=other edge → LED 115=edge
    // Must be reversed so it aligns spatially with strip 1
    _strip.setPixelColor(globals::NUMBER_OF_LEDS_IN_LED_STRIP_1 + r, v.at(globals::NUMBER_OF_LEDS_IN_LED_STRIP_1 - 1 - r));
  }
  _strip.show();
}

}