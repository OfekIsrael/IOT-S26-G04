#pragma once

#include <Arduino.h>
#include <cassert>
#include "globals.h"

extern void webPrint(String msg);
extern void webPrintln(String msg);

namespace hall {

namespace {
unsigned long _time_of_last_detection_in_microseconds;
unsigned long _last_period;
float _moving_average;
bool _did_interrupt_just_occur;
unsigned long _max_period;
unsigned long _min_period;

unsigned long _last_debug_print_time = 0; 
int _interrupts_this_second = 0; // NEW: Tracks triggers safely
}

void IRAM_ATTR magnet_detect() {
  unsigned long new_time = micros();
  unsigned long potential_last_period = new_time - _time_of_last_detection_in_microseconds;
  
  // 50ms Debounce (Max 1200 RPM allowed)
  if (potential_last_period > 50000) {  
    _last_period = potential_last_period;
    _time_of_last_detection_in_microseconds = new_time;
    _did_interrupt_just_occur = true;
    _interrupts_this_second++; // Add to our tally!
  }
}

void begin() {
  _time_of_last_detection_in_microseconds = micros();
  _last_period = 1000000;
  _moving_average = 1000000;
  _did_interrupt_just_occur = false;
  _max_period = 1000000;
  _min_period = 1000000;
  _last_debug_print_time = micros();

  pinMode(globals::PIN_NUMBER_OF_HALL_SENSOR, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(globals::PIN_NUMBER_OF_HALL_SENSOR), magnet_detect, FALLING); // FALLING is usually standard for Hall Sensors
  webPrintln("Hall sensor initialized. Awaiting magnet...");
}

int get_angle() {
  if (_did_interrupt_just_occur) {
    _did_interrupt_just_occur = false;
    _moving_average = (_moving_average * globals::BETA) + (_last_period * globals::ALPHA);
    if (_moving_average > globals::MAX_PERIOD_TIME_IN_MICRO_SEC) {
      _moving_average = globals::MAX_PERIOD_TIME_IN_MICRO_SEC;
    }
    _max_period = max(_last_period, _max_period);
    _min_period = min(_last_period, _min_period);
  }

  // --- SAFE TELEMETRY REPORTING (Once per second max) ---
  if (micros() - _last_debug_print_time > 1000000) {
    int raw_state = digitalRead(globals::PIN_NUMBER_OF_HALL_SENSOR);
    float current_rpm = 60000000.0 / _moving_average;
    
    // Timeout if motor stops
    if (micros() - _time_of_last_detection_in_microseconds > 1000000) {
      current_rpm = 0.0;
    }

    String logMsg = "[Sensor] Pin 15: ";
    logMsg += (raw_state == HIGH ? "HIGH" : "LOW");
    logMsg += " | Triggers: ";
    logMsg += String(_interrupts_this_second); // Print how many times it fired!
    logMsg += " | RPM: ";
    logMsg += String(current_rpm, 1);
    
    webPrintln(logMsg);
    
    _interrupts_this_second = 0; // Reset the counter for the next second
    _last_debug_print_time = micros();
  }

  int T = (int)floor(_moving_average);
  if (T < 1) T = 1; 
  
  int current_delta = (micros() - _time_of_last_detection_in_microseconds) % T;
  float percentage_of_circle = ((float)current_delta) / T;
  float float_angle = percentage_of_circle * 360;
  int rounded_angle = (int)float_angle;
  return (360 - rounded_angle) % 360;
}

}