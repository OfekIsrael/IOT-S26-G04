#pragma once
#include <math.h>
#include "config.h"
#include "canvas.h"
#include "leds.h"
#include <Adafruit_NeoPixel.h>

namespace renderer {

  int8_t _lut_i[config::NUM_ANGLES][config::NUM_LEDS_PER_STRIP];
  int8_t _lut_j[config::NUM_ANGLES][config::NUM_LEDS_PER_STRIP];

  void _build_lut() {
    const float center = (config::CANVAS_SIZE - 1) / 2.0f;
    for (int a = 0; a < config::NUM_ANGLES; a++) {
      float angle_deg = a * config::ANGLE_STEP;
      float angle_rad = angle_deg * PI / 180.0f;
      float dx = cos(angle_rad);
      float dy = sin(angle_rad);

      for (int r = 0; r < config::NUM_LEDS_PER_STRIP; r++) {
        // Map r=0 to one edge, r=57 to the other edge, through center
        float radius = r - center;
        int ci = (int)round(center + dx * radius);
        int cj = (int)round(center + dy * radius);
        // Clamp
        ci = max(0, min(config::CANVAS_SIZE - 1, ci));
        cj = max(0, min(config::CANVAS_SIZE - 1, cj));
        _lut_i[a][r] = (int8_t)ci;
        _lut_j[a][r] = (int8_t)cj;
      }
    }
  }

  void begin() {
    _build_lut();
  }

  // angle must be 0-359.
  void render(int angle) {
    int slice = (angle / config::ANGLE_STEP) % config::NUM_ANGLES;

    uint32_t colors[config::NUM_LEDS_PER_STRIP];
    for (int r = 0; r < config::NUM_LEDS_PER_STRIP; r++) {
      uint8_t ri, gi, bi;
      canvas::get_pixel(_lut_i[slice][r], _lut_j[slice][r], ri, gi, bi);
      colors[r] = Adafruit_NeoPixel::Color(ri, gi, bi);
    }
    leds::display(colors);
  }

  // Call this whenever canvas content changes to flush
  // any cached state (reserved for future optimisation).
  void invalidate() {}

}