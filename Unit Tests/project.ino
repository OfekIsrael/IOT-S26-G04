#include "ota.h"
#include <Adafruit_NeoPixel.h>
#include "SECRETS.h"
#include "leds.h"
#include "renderer.h"
#include "test_renderer.h"
#include "hall.h"
#include "test_patterns.h"
#include "test_segment.h"

String input_buf = "";

void setup() {
  Serial.begin(115200);
  ota::begin();
  leds::begin();
  canvas::begin();
  renderer::begin();
  hall::begin();

  // test_patterns::horizontal_line(); // Bypassed for segment test
}

void loop() {
  ota::update();
  int angle = hall::get_angle();

  // Render a quarter circle (0 to 90 degrees) in White
  // Change 90 to 30 or any degree to test resolution boundaries
  test_segment::render(angle, 0, 90, 255, 255, 255);
  
  // Run the drift diagnosis test
  // This will draw 4 colored spokes (Red at 0, Green at 90, Blue at 180, Yellow at 270)
  // test_segment::render_spokes(angle);
}
