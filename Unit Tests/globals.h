#pragma once

namespace globals {

const int PIN_NUMBER_OF_LED_STRIP_1 = 13;          
const int NUMBER_OF_LEDS_IN_LED_STRIP_1 = 58;  // The logical image radius
const int PHYSICAL_LED_COUNT = 116;            // NEW: The actual hardware count

const int PIN_NUMBER_OF_HALL_SENSOR = 15;          
const int IMAGE_SIZE_IN_BYTES = (NUMBER_OF_LEDS_IN_LED_STRIP_1 * NUMBER_OF_LEDS_IN_LED_STRIP_1 * 3);
const int SINGLE_COLOR_SIZE_IN_BYTES = (NUMBER_OF_LEDS_IN_LED_STRIP_1 * NUMBER_OF_LEDS_IN_LED_STRIP_1);

const float ALPHA = 0.01;  
const float BETA = 1 - ALPHA;

const int NUM_OF_ANGLES = 180;
const int DISTANCE_BETWEEN_ANGLES = 2;

const float MAX_PERIOD_TIME_IN_MICRO_SEC = 500000;
}