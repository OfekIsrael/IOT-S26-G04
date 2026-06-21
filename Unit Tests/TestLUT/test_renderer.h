#pragma once

#include "canvas.h"
#include "config.h"

/*
This test file is meant for testing the rendering system.
We are checking that if we give a set angle, the correct LEDs are turned on in the correct color.
*/

namespace test_renderer {
    void pattern_center_dot() {
    canvas::clear();
    canvas::set_pixel(28, 28, 255, 255, 255);
    canvas::set_pixel(28, 29, 255, 255, 255);
    canvas::set_pixel(29, 28, 255, 255, 255);
    canvas::set_pixel(29, 29, 255, 255, 255);
  }

  // Pattern B: horizontal line across full canvas at row 28
  // i=28, j=0..57, all red
  // This line lies along angle=0 (and angle=180).
  // WORKS
  void pattern_horizontal_line() {
    canvas::clear();
    for (int j = 0; j < config::CANVAS_SIZE; j++) {
      canvas::set_pixel(28, j, 255, 0, 0);
      canvas::set_pixel(29, j, 255, 0, 0);
    }
  }

  // Pattern C: vertical line down full canvas at col 28
  // i=0..57, j=28, all blue
  // This line lies along angle=90 (and angle=270).
  // WORKS
  void pattern_vertical_line() {
    canvas::clear();
    for (int i = 0; i < config::CANVAS_SIZE; i++) {
      canvas::set_pixel(i, 28, 0, 0, 255);
      canvas::set_pixel(i, 29, 0, 0, 255);
    }
  }

  // Pattern D: both lines together — red horizontal, blue vertical
  // At angle=0 arm should be fully red.
  // At angle=90 arm should be fully blue.
  // At angle=45 arm should be dark (diagonal misses both lines)
  // except at the center pixel where they cross (white).
  // WORKS
  void pattern_cross() {
    canvas::clear();
    for (int j = 0; j < config::CANVAS_SIZE; j++) {
      canvas::set_pixel(28, j, 255, 0, 0); // horizontal red
      canvas::set_pixel(29, j, 255, 0, 0); // horizontal red
    }
    for (int i = 0; i < config::CANVAS_SIZE; i++) {
      canvas::set_pixel(i, 28, 0, 0, 255); // vertical blue
      canvas::set_pixel(i, 29, 0, 0, 255); // vertical blue
    }
    // Center pixel where they cross: make it white so it's always visible
    canvas::set_pixel(28, 28, 255, 255, 255);
    canvas::set_pixel(28, 29, 255, 255, 255);
    canvas::set_pixel(29, 28, 255, 255, 255);
    canvas::set_pixel(29, 29, 255, 255, 255);
  }

  // Pattern E: asymmetric — one bright pixel off-center
  // Placed at (28, 42): same row as center, 14 pixels to the right.
  // At angle=0 this pixel is 14 LEDs from center toward LED 57 end.
  // At angle=180 this pixel is 14 LEDs from center toward LED 0 end.
  // At angle=90 this pixel is invisible (not on the vertical line).
  // WORKS
  void pattern_off_center_dot() {
    canvas::clear();
    canvas::set_pixel(28, 42, 255, 165, 0); // orange
    canvas::set_pixel(29, 42, 255, 165, 0);
    canvas::set_pixel(28, 41, 255, 165, 0);
    canvas::set_pixel(29, 41, 255, 165, 0);
  }
}