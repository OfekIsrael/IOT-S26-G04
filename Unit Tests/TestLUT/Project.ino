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
  //int angle = hall::get_angle();
  //renderer::render(angle);
  
  while (Serial.available()) {
    char c = Serial.read();
    
    if (c == '\n' || c == '\r') {
      input_buf.trim();
      
      if (input_buf == "a") {
        test_renderer::pattern_center_dot();  
        renderer::render(0);
      } else if (input_buf == "b") {
        test_renderer::pattern_horizontal_line(); 
        renderer::render(0);
      } else if (input_buf == "c") {
        test_renderer::pattern_vertical_line();   
        renderer::render(90);
      } else if (input_buf == "d") {
        test_renderer::pattern_cross();           
        renderer::render(0);
      } else if (input_buf == "e") {
        test_renderer::pattern_off_center_dot();  
        renderer::render(0);
      } else if (input_buf.length() > 0) {
        int angle = input_buf.toInt();
        if (angle >= 0 && angle <= 359) {
          renderer::render(angle);
        }
      }
      
      input_buf = ""; 
      
    } else {
      input_buf += c;
    }
  }
  
}