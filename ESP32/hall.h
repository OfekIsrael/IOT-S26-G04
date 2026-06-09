#pragma once
#include <Arduino.h>
#include <cassert>
#include "config.h"

/*
Hall Logic. Includes Printing of data (RPM, Angle) to OTA terminal
*/

namespace ota {
  extern void webPrint(String msg);
  extern void webPrintln(String msg);
}

namespace hall {

  volatile unsigned long _last_trigger_us = 0;
  volatile unsigned long _period_us       = 1000000;
  volatile bool          _triggered       = false;
  float _smoothed_period_us               = 1000000.0f;

  // Interrupt Service Routine - Hall Sensor Interrupt function, triggered on hardware event.
  void IRAM_ATTR _isr() {
    unsigned long now = micros();
    unsigned long delta = now - _last_trigger_us;
    if (delta > (unsigned long)config::DEBOUNCE_US) {
      _period_us       = delta;
      _last_trigger_us = now;
      _triggered       = true;
    }
  }

  void begin() {
    _last_trigger_us = micros();
    pinMode(config::PIN_HALL_SENSOR, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(config::PIN_HALL_SENSOR),
                    _isr, FALLING);
  }

  // Returns current angle 0-359 (estimate). Call every loop iteration.
  int get_angle() {
    // Safely copy volatile values
    noInterrupts();
    unsigned long period   = _period_us;
    unsigned long last     = _last_trigger_us;
    bool triggered         = _triggered;
    _triggered             = false;
    interrupts();

    if (triggered) {
      _smoothed_period_us = _smoothed_period_us * (1.0f - config::HALL_EMA_ALPHA)
                          + period              *         config::HALL_EMA_ALPHA;
      // Clamp to valid range
      if (_smoothed_period_us > config::MAX_PERIOD_US)
        _smoothed_period_us = config::MAX_PERIOD_US;
    }

    unsigned long elapsed = micros() - last;
    if (elapsed > (unsigned long)_smoothed_period_us)
      elapsed = (unsigned long)_smoothed_period_us;

    float fraction = (float)elapsed / _smoothed_period_us;

    int angle = (int)(fraction * 360.0f) % 360;

    String logMsg = "[Sensor] Pin 15: ";
    logMsg += "RPM: ";
    logMsg += String(60000000.0f / _smoothed_period_us, 1);
    logMsg += " | Angle: ";
    logMsg += String(angle);
    
    ota::webPrintln(logMsg);

    return angle;
  }

  float get_rpm() {
    return 60000000.0f / _smoothed_period_us;
  }
}