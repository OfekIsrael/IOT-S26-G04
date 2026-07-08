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

  volatile uint32_t _current_angle   = 0;
  volatile uint32_t _period_us       = 1000000;
  volatile uint32_t _last_trigger_us = 0;
  hw_timer_t *      _timer           = nullptr;

  unsigned long _last_print_ms       = 0;

  // Interrupt Service Routine - Hardware Timer
  void IRAM_ATTR _timer_isr() {
    // Hardcode 360 instead of config::NUM_ANGLES to guarantee we don't read from Flash memory
    _current_angle = (_current_angle + 1) % 360; 
  }

  // Interrupt Service Routine - Hall Sensor
  void IRAM_ATTR _hall_isr() {
    uint32_t now = micros();
    uint32_t delta = now - _last_trigger_us;
    _last_trigger_us = now;

    // Use a hardcoded integer (50000) instead of config::DEBOUNCE_US
    // Reading floating point constants from config.h inside an ISR causes a Flash Cache crash!
    if (delta > 50000) { 
      _period_us = delta;

      uint32_t tick_us = _period_us / 360;
      if (tick_us < 1) tick_us = 1;
      
      // Safety check: ensure timer is initialized before writing to it
      if (_timer != nullptr) {
        timerAlarmWrite(_timer, tick_us, true);
      }
    }
    
    _current_angle = 0;
  }

  void begin() {
    // 1. Initialize the timer FIRST to prevent a nullptr crash if the Hall sensor triggers immediately
    _timer = timerBegin(0, 80, true);
    timerAttachInterrupt(_timer, &_timer_isr, true);
    timerAlarmWrite(_timer, 1000, true);
    timerAlarmEnable(_timer);

    // 2. Attach the Hall sensor interrupt SECOND
    _last_trigger_us = micros();
    pinMode(config::PIN_HALL_SENSOR, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(config::PIN_HALL_SENSOR), _hall_isr, FALLING);
  }

  // Returns current angle instantly from the timer state
  int get_angle() {
    uint32_t angle = _current_angle; // Fast atomic read
    
    // Rate-limit the network printing to twice a second to avoid stalling the ESP32
    unsigned long now_ms = millis();
    if (now_ms - _last_print_ms >= 500) {
      _last_print_ms = now_ms;
      
      uint32_t period = _period_us;
      float rpm = (period > 0) ? (60000000.0f / period) : 0.0f;
      
      String logMsg = "[Sensor] Pin 15: RPM: ";
      logMsg += String(rpm, 1);
      logMsg += " | Angle: ";
      logMsg += String(angle);
      
      ota::webPrintln(logMsg);
    }

    return angle;
  }

  float get_rpm() {
    uint32_t p = _period_us;
    if (p == 0) return 0.0f;
    return 60000000.0f / p;
  }
}