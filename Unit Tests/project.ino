#include "ota.h"
#include <Adafruit_NeoPixel.h>
#include "SECRETS.h"
#include "leds.h"
#include "renderer.h"
#include "test_renderer.h"
#include "hall.h"
#include "test_patterns.h"

String input_buf = "";

void setup() {
  Serial.begin(115200);
  ota::begin();
  leds::begin();
  canvas::begin();
  renderer::begin();
  hall::begin();

  test_patterns::horizontal_line();
}

void loop() {
  ota::update();
  int angle = hall::get_angle();
  renderer::render(angle);
}
