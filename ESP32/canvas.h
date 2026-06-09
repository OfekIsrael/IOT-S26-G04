#pragma once
#include "config.h"
#include <stdint.h>

namespace canvas {

  uint8_t _r[config::CANVAS_SIZE][config::CANVAS_SIZE];
  uint8_t _g[config::CANVAS_SIZE][config::CANVAS_SIZE];
  uint8_t _b[config::CANVAS_SIZE][config::CANVAS_SIZE];

  void clear() {
    memset(_r, 0, sizeof(_r));
    memset(_g, 0, sizeof(_g));
    memset(_b, 0, sizeof(_b));
  }

  void begin() { clear(); }

  void set_pixel(int i, int j, uint8_t r, uint8_t g, uint8_t b) {
    if (i < 0 || i >= config::CANVAS_SIZE) return;
    if (j < 0 || j >= config::CANVAS_SIZE) return;
    _r[i][j] = r;
    _g[i][j] = g;
    _b[i][j] = b;
  }

  void get_pixel(int i, int j, uint8_t& r, uint8_t& g, uint8_t& b) {
    r = _r[i][j];
    g = _g[i][j];
    b = _b[i][j];
  }

}