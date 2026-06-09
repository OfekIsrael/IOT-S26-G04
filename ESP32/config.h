#pragma once

namespace config {
  constexpr int PIN_LED_STRIP        = 13;
  constexpr int PIN_HALL_SENSOR      = 15;

  constexpr int NUM_LEDS_PER_STRIP   = 58;
  constexpr int TOTAL_LEDS           = 116;

  constexpr int CANVAS_SIZE          = 58;

  constexpr int NUM_ANGLES           = 360;
  constexpr int ANGLE_STEP           = 1; // Degrees between slices (360/NUM_ANGLES)

  constexpr float MAX_PERIOD_US      = 500000.0f;  // 120 RPM minimum
  constexpr float DEBOUNCE_US        = 50000.0f;   // 1200 RPM maximum
  constexpr float HALL_EMA_ALPHA     = 0.01f;      // Period smoothing factor

  constexpr int BT_IMAGE_SIZE_BYTES  = CANVAS_SIZE * CANVAS_SIZE * 3;
}