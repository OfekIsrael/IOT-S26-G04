// test_patterns.h
#pragma once
#include <math.h>
#include "canvas.h"
#include "config.h"

/*
This test file is meant for displaying simple shapes on the LED display.
Currently all of the shapes are displayed, but the image does not look good.
The image is either moving, not displaying at the right moments or flashing.
We think that this is probably a problem with the hardware, and that the sensor sampling does not match.
*/

namespace test_patterns {

  void clear() { canvas::clear(); }

  // Simple Horizontal Line
  void horizontal_line() {
    for (int j = 0; j < config::CANVAS_SIZE; j++) {
      canvas::set_pixel(27, j, 255, 0, 255);
      canvas::set_pixel(28, j, 255, 0, 255);
      canvas::set_pixel(29, j, 255, 0, 255);
      canvas::set_pixel(30, j, 255, 0, 255);
    }
  }

  // The thick-X pattern
  void cross(uint8_t r=255, uint8_t g=0, uint8_t b=0, int thickness=3) {
    canvas::clear();
    int N = config::CANVAS_SIZE;
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) {
        int d1 = abs(i - j);
        int d2 = abs(i - (N - 1 - j));
        if (d1 <= thickness || d2 <= thickness)
          canvas::set_pixel(i, j, r, g, b);
      }
  }

  // Square outline with a marked corner
  void square() {
    canvas::clear();
    int cx = config::CANVAS_SIZE / 2;
    int cy = config::CANVAS_SIZE / 2;
    int half = 16, t = 2;
    for (int i = 0; i < config::CANVAS_SIZE; i++)
      for (int j = 0; j < config::CANVAS_SIZE; j++) {
        int dx = abs(i - cx), dy = abs(j - cy);
        bool h_edge = (dx <= half) && (dy >= half - t) && (dy <= half);
        bool v_edge = (dy <= half) && (dx >= half - t) && (dx <= half);
        if (h_edge || v_edge) canvas::set_pixel(i, j, 93, 202, 165);
        // Marked corner (top-right)
        if (i >= cx && i <= cx+half && j >= cy-half && j <= cy-half+4)
          canvas::set_pixel(i, j, 250, 100, 80);
      }
  }

  // Bullseye with spoke
  void bullseye() {
    canvas::clear();
    int cx = config::CANVAS_SIZE / 2;
    int cy = config::CANVAS_SIZE / 2;
    for (int i = 0; i < config::CANVAS_SIZE; i++) {
      for (int j = 0; j < config::CANVAS_SIZE; j++) {
        int dx = i - cx, dy = j - cy;
        float r = sqrt((float)(dx*dx + dy*dy));
        if      (r <= 3.0f)                  canvas::set_pixel(i,j,250,199,117);
        else if (r >= 8.0f  && r <= 12.0f)   canvas::set_pixel(i,j,240,153,123);
        else if (r >= 20.0f && r <= 24.0f)   canvas::set_pixel(i,j, 93,202,165);
        else if (dx >= 5 && dx <= 26 && abs(dy) <= 2)
                                             canvas::set_pixel(i,j,127,121,221);
      }
    }
  }
}