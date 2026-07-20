# Installation and Compilation

## 1. ESP32 Firmware
1. Open `ESP32/ESP32.ino` in the Arduino IDE.
2. Select your ESP32 board from the **Tools > Board** menu (e.g., "ESP32 Dev Module").
3. Make sure you have the `Adafruit NeoPixel` library installed via the Library Manager.
4. Verify the `NUM_SLICES` and `NUM_LEDS` match your physical hardware.
5. Click **Upload** to flash the code to the ESP32.

## 2. Flutter Mobile App
1. Make sure you have the Flutter SDK installed.
2. Open a terminal in the `flutter_app` directory.
3. Run `flutter pub get` to download all dependencies.
4. Connect your Android device via USB (or use an emulator with Bluetooth passthrough).
5. Run `flutter run --release` or build an APK using `flutter build apk --release`.
6. Install the resulting APK on your Android device.

## 3. Hardware Assembly
- Connect the WS2812B Data pin to GPIO 13 on the ESP32.
- Connect the Hall Effect Sensor signal pin to GPIO 15.
- Ensure power and grounds are properly shared between the ESP32, the LED strip, and the motor controller.
