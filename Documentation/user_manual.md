# User Manual & Operating Instructions

## Connecting the App
1. Power on the ESP32 and spin the motor.
2. Open the Flutter app on your phone.
3. Tap the Bluetooth icon to scan for devices.
4. Select the POV Display from the list. Once connected, the app will sync with the hardware.

## System Statuses & Error Messages
* **"Transmitting drawing to ESP32..."** - SHOWN AS: A snackbar message in the app. Indicates BLE packet transmission has started.
* **"Image beamed successfully!"** - SHOWN AS: A green snackbar. Indicates the full 54-slice array has been acknowledged by the ESP32.
* **"Failed to send. Check Bluetooth."** - SHOWN AS: A red snackbar. Happens if the BLE connection drops during transmission.
* **Gap/Flicker on Display** - Occurs if the fan speed drops too low, triggering the auto-shutdown safety timeout (>500ms between rotations).

## Features & UI
* **Upload Image**: Select an image from your gallery. The app mathematically converts it to a polar coordinate matrix and beams it to the fan.
* **Live Weather**: Fetches real-time temperature and displays it as text.
* **RPM Screen**: Shows real-time motor speed (fetched via the Hall Effect sensor).
* **POV Canvas / Playground**: Allows you to manually draw pixels on a circular grid and instantly mirror the drawing to the fan.
* **Brightness Slider**: Drag the slider on the main page to dynamically adjust the LED brightness over BLE.

## Calibration Instructions
There is no manual software calibration required for daily operation. 
However, if you physically alter the magnet position or the number of LEDs:
1. Update `NUM_SLICES` or `NUM_LEDS` in `ESP32/ProjectBLE/ProjectBLE.ino`.
2. Update the corresponding `PovConfig.numSlices` or `PovConfig.numRings` in `flutter_app/lib/config.dart`.
3. Recompile and upload both components.
