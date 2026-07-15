# Project Parameters

The following parameters are hardcoded into the project and require recompilation to update.

## ESP32 Parameters (`ProjectBLE.ino`)
These are defined at the top of the `ProjectBLE.ino` file:

* `NUM_SLICES` (Default: 54) - The total number of angular slices the fan is divided into for one 360-degree rotation.
* `NUM_LEDS` (Default: 29) - The number of WS2812B NeoPixel LEDs mounted on the physical fan arm.
* `BRIGHTNESS` (Default: 40) - The default boot brightness (0-255) of the LEDs before being overridden by the app.
* `LED_PIN` (Default: 13) - The GPIO pin the NeoPixel data line is connected to.
* `HALL_PIN` (Default: 15) - The GPIO pin the Hall Effect sensor data line is connected to.

### BLE UUIDs
* `SERVICE_UUID` (`4fafc201-1fb5-459e-8fcc-c5c9c331914b`) - The main Bluetooth Low Energy service ID.
* `CHARACTERISTIC_UUID` (`beb5483e-36e1-4688-b7f5-ea07361b26a8`) - The characteristic used to receive 88-byte pattern packets (image/text data).
* `RPM_CHAR_UUID` (`d203a55e-a6a9-4673-9a3b-28564a51e605`) - The characteristic used to notify the app of real-time RPM updates.
* `BRIGHTNESS_CHAR_UUID` (`b4250400-f38b-4a37-b64d-7bcda53f932e`) - The characteristic used to receive brightness adjustments.

## Flutter App Parameters (`flutter_app/lib/config.dart`)
These parameters ensure the mobile app maths match the physical hardware:

* `PovConfig.numSlices` (Default: 54) - Must perfectly match `NUM_SLICES` on the ESP32. Used for polar math, image scaling, and text alignment.
* `PovConfig.numRings` (Default: 29) - Must perfectly match `NUM_LEDS` on the ESP32.
