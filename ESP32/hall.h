/// ********************************************************************************************************************
/// multiple include protection
/// ********************************************************************************************************************

#pragma once

/// ********************************************************************************************************************
/// includes
/// ********************************************************************************************************************

#include <Arduino.h>
#include <cassert>
#include "globals.h"

/// ********************************************************************************************************************
/// namespace definition
/// ********************************************************************************************************************

namespace hall {

/// ********************************************************************************************************************
/// protected variable
/// ********************************************************************************************************************

namespace {
unsigned long _time_of_last_detection_in_microseconds;
unsigned long _last_period;
float _moving_average;
bool _did_interrupt_just_occur;
unsigned long _max_period;
unsigned long _min_period;
}

/// ********************************************************************************************************************
/// functions
/// ********************************************************************************************************************

void IRAM_ATTR magnet_detect() {
  unsigned long new_time = micros();
  unsigned long potential_last_period = new_time - _time_of_last_detection_in_microseconds;
  // protect from multiple interrupts that are very close together
  if (potential_last_period > 50000) {  // no less than 50 ms (cannot handle more than 1200 rpm)
    _last_period = potential_last_period;
    _time_of_last_detection_in_microseconds = new_time;
    _did_interrupt_just_occur = true;
  }
}

void begin() {
  _time_of_last_detection_in_microseconds = micros();
  _last_period = 1000000;
  _moving_average = 1000000;
  _did_interrupt_just_occur = false;
  _max_period = 1000000;
  _min_period = 1000000;
  pinMode(globals::PIN_NUMBER_OF_HALL_SENSOR, INPUT);
  attachInterrupt(digitalPinToInterrupt(globals::PIN_NUMBER_OF_HALL_SENSOR), magnet_detect, RISING);
  Serial.println("hall initialized.");
}

void printHallReading() {
#if PRINT_HALL_READING_EVERY_TIME_WE_GET_ANGLE
  if (micros() % 100 == 0) {
    int analog_hall_reading = analogRead(globals::PIN_NUMBER_OF_HALL_SENSOR);  //Read the sensor
    int digital_hall_reading = digitalRead(globals::PIN_NUMBER_OF_HALL_SENSOR);
    Serial.print("analog_hall_reading = ");
    Serial.print(analog_hall_reading);
    Serial.print("\t\t digital_hall_reading = ");
    Serial.println(digital_hall_reading);
  }
#endif
}

void printHallLastPeriod() {
#if PRINT_LAST_PERIOD_TIME_AFTER_INTERRUPT
  Serial.print("last_period = ");
  Serial.print(_last_period);
  Serial.print(", moving_average = ");
  Serial.println(_moving_average);
#endif
}

void printHallStats() {
  Serial.print("moving_average = ");
  Serial.print(_moving_average);
  Serial.print(", max_period = ");
  Serial.print(_max_period);
  Serial.print(", min_period = ");
  Serial.println(_min_period);
  _min_period = _last_period;
  _max_period = _last_period;
}

int get_angle() {
  printHallReading();
  if (_did_interrupt_just_occur) {
    _did_interrupt_just_occur = false;
    _moving_average = (_moving_average * globals::BETA) + (_last_period * globals::ALPHA);
    if (_moving_average > globals::MAX_PERIOD_TIME_IN_MICRO_SEC) {
      _moving_average = globals::MAX_PERIOD_TIME_IN_MICRO_SEC;
    }
    _max_period = max(_last_period, _max_period);
    _min_period = min(_last_period, _min_period);
    printHallLastPeriod();
  }
  int T = (int)floor(_moving_average);
  int current_delta = (micros() - _time_of_last_detection_in_microseconds) % T;
  float percentage_of_circle = ((float)current_delta) / T;
  float float_angle = percentage_of_circle * 360;
  int rounded_angle = (int)float_angle;
  // the fan spins the opposite direction.
  return (360 - rounded_angle) % 360;
}

}