#pragma once
#include <Adafruit_NeoPixel.h>
#include "config.h"

namespace leds {

  Adafruit_NeoPixel _strip(config::TOTAL_LEDS, config::PIN_LED_STRIP,
                            NEO_GRB + NEO_KHZ800);

  void begin() {
    _strip.begin();
    _strip.clear();
    _strip.show();
  }

  // Takes 58 colors representing one full diameter slice (edge→edge)
  // and maps them correctly onto both physical strips.
  void display(const uint32_t colors[config::NUM_LEDS_PER_STRIP]) {
    for (int r = 0; r < config::NUM_LEDS_PER_STRIP; r++) {
      _strip.setPixelColor(r, colors[r]);
      _strip.setPixelColor(config::NUM_LEDS_PER_STRIP + r,
                           colors[config::NUM_LEDS_PER_STRIP - 1 - r]);
    }
    _strip.show();
  }

  void clear() {
    _strip.clear();
    _strip.show();
  }

  void light_one(int index, uint32_t color, bool clear_first = true) {
    if (clear_first) _strip.clear();
    _strip.setPixelColor(index, color);
    _strip.show();
  }

  /*
  LED test 01
  Test that the indexing of the LED strips are correct
  First strip - Red, Green, Blue (Left, Middle, Right)
  Second strip - Yellow, Cyan, White (Right, Middle, Left)
  WORKS
  */

  void test_01() {
    _strip.clear();
    _strip.setPixelColor(0,   _strip.Color(255,   0,   0)); // RED
    _strip.setPixelColor(29,  _strip.Color(  0, 255,   0)); // GREEN
    _strip.setPixelColor(57,  _strip.Color(  0,   0, 255)); // BLUE
    _strip.setPixelColor(58,  _strip.Color(255, 255,   0)); // YELLOW
    _strip.setPixelColor(86,  _strip.Color(  0, 255, 255)); // CYAN
    _strip.setPixelColor(115, _strip.Color(255, 255, 255)); // WHITE
    _strip.show();
  }

  /*
  LED test 02
  Test that All LEDs are working
  WORKS
  */

  void test_02() {

    for(int i = 0; i < config::TOTAL_LEDS; i++) {
      _strip.setPixelColor(i,   _strip.Color(i,   i + 25,   i + 50));
    }
    _strip.show();
  }

}