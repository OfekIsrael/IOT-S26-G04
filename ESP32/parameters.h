#pragma once

#define PIN_NUMBER_OF_LED_STRIP_1 = 13;
#define NUMBER_OF_LEDS_IN_LED_STRIP_1 = 58;
#define PIN_NUMBER_OF_HALL_SENSOR = 15;
#define IMAGE_SIZE_IN_BYTES = (NUMBER_OF_LEDS_IN_LED_STRIP_1 * NUMBER_OF_LEDS_IN_LED_STRIP_1 * 3);
#define SINGLE_COLOR_SIZE_IN_BYTES = (NUMBER_OF_LEDS_IN_LED_STRIP_1 * NUMBER_OF_LEDS_IN_LED_STRIP_1);


namespace globals {

// const float ALPHA = 0.01;  // moving average weight, the smaller the number the slower the average moves
// const float BETA = 1 - ALPHA;

/*
number of angles
const int NUM_OF_ANGLES = 180;
const int DISTANCE_BETWEEN_ANGLES = 2;
*/

// period calculation
// const float MAX_PERIOD_TIME_IN_MICRO_SEC = 500000;
}