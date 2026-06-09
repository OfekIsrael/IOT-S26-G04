#pragma once
#include "config.h"
#include "leds.h" // Needed to access the _strip object

/*
This test file was meant to make sure that the LEDs are working and that we are indexing them correctly.
*/

namespace test_leds {

  /*
  LED test 01
  Test that the indexing of the LED strips are correct
  First strip - Red, Green, Blue (Left, Middle, Right)
  Second strip - Yellow, Cyan, White (Right, Middle, Left)
  WORKS
  */
  void test_01() {
    leds::_strip.clear();
    leds::_strip.setPixelColor(0,   leds::_strip.Color(255,   0,   0)); // RED
    leds::_strip.setPixelColor(29,  leds::_strip.Color(  0, 255,   0)); // GREEN
    leds::_strip.setPixelColor(57,  leds::_strip.Color(  0,   0, 255)); // BLUE
    leds::_strip.setPixelColor(58,  leds::_strip.Color(255, 255,   0)); // YELLOW
    leds::_strip.setPixelColor(86,  leds::_strip.Color(  0, 255, 255)); // CYAN
    leds::_strip.setPixelColor(115, leds::_strip.Color(255, 255, 255)); // WHITE
    leds::_strip.show();
  }

  /*
  LED test 02
  Test that All LEDs are working
  WORKS
  */
  void test_02() {
    for(int i = 0; i < config::TOTAL_LEDS; i++) {
      leds::_strip.setPixelColor(i,   leds::_strip.Color(i,   i + 25,   i + 50));
    }
    leds::_strip.show();
  }

}