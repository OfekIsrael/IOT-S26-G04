#pragma once
#include <Adafruit_NeoPixel.h>
#include "config.h"
#include "leds.h"

namespace test_segment {

    // Helper to check if an angle is within a segment
    bool is_in_segment(int current_angle, int start_angle, int end_angle) {
        // Normalize angles to 0-359
        start_angle = (start_angle % 360 + 360) % 360;
        end_angle = (end_angle % 360 + 360) % 360;
        current_angle = (current_angle % 360 + 360) % 360;

        if (start_angle <= end_angle) {
            return current_angle >= start_angle && current_angle <= end_angle;
        } else {
            // Segment wraps around 0 degrees
            return current_angle >= start_angle || current_angle <= end_angle;
        }
    }

    void render(int current_angle, int start_angle = 0, int end_angle = 90, uint8_t r = 255, uint8_t g = 255, uint8_t b = 255) {
        uint32_t colors[config::NUM_LEDS_PER_STRIP];
        
        uint32_t active_color = Adafruit_NeoPixel::Color(r, g, b);
        
        int opposite_angle = (current_angle + 180) % 360;
        bool forward_in_segment = is_in_segment(current_angle, start_angle, end_angle);
        bool backward_in_segment = is_in_segment(opposite_angle, start_angle, end_angle);

        float center = (config::NUM_LEDS_PER_STRIP - 1) / 2.0f;

        for (int i = 0; i < config::NUM_LEDS_PER_STRIP; i++) {
            if (i >= center) { // Forward half
                colors[i] = forward_in_segment ? active_color : 0;
            } else {           // Backward half
                colors[i] = backward_in_segment ? active_color : 0;
            }
        }
        
        // Use the physical mapping provided by the leds namespace
        leds::display(colors);
    }

    uint32_t _get_spoke_color(int angle, int thickness) {
        if (is_in_segment(angle, 0, thickness - 1)) return Adafruit_NeoPixel::Color(255, 0, 0);
        if (is_in_segment(angle, 90, 90 + thickness - 1)) return Adafruit_NeoPixel::Color(0, 255, 0);
        if (is_in_segment(angle, 180, 180 + thickness - 1)) return Adafruit_NeoPixel::Color(0, 0, 255);
        if (is_in_segment(angle, 270, 270 + thickness - 1)) return Adafruit_NeoPixel::Color(255, 255, 0);
        return 0;
    }

    // A special test to diagnose interpolation drift.
    // Draws very thin spokes at 0 (Red), 90 (Green), 180 (Blue), and 270 (Yellow).
    // Thickness determines how many degrees wide the spoke is (minimum 1).
    void render_spokes(int current_angle, int thickness = 2) {
        uint32_t colors[config::NUM_LEDS_PER_STRIP];
        
        int opposite_angle = (current_angle + 180) % 360;
        uint32_t forward_color = _get_spoke_color(current_angle, thickness);
        uint32_t backward_color = _get_spoke_color(opposite_angle, thickness);

        float center = (config::NUM_LEDS_PER_STRIP - 1) / 2.0f;

        for (int i = 0; i < config::NUM_LEDS_PER_STRIP; i++) {
            if (i >= center) { // Forward half
                colors[i] = forward_color;
            } else {           // Backward half
                colors[i] = backward_color;
            }
        }
        
        leds::display(colors);
    }
}
