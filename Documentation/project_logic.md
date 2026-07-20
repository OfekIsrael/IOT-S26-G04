# Holographic POV App: Technical Deep Dive

This document provides a detailed breakdown of the Flutter app's internal mechanics, perfect for understanding exactly how the software manipulates data before transmitting it to the physical POV hardware.

The core philosophy of this project is **"Smart Client, Dumb Hardware."** Instead of making the ESP32 decode images or calculate text rendering, the smartphone utilizes its powerful processor to calculate every single pixel mathematically and spoon-feeds raw, finalized color packets to the ESP32.

---

## 1. Core Configuration (`lib/config.dart`)
All geometry math in the app is driven by a single source of truth: `PovConfig`.
* `PovConfig.numSlices (54)`: Represents the number of angular subdivisions the physical fan is divided into for a 360-degree rotation.
* `PovConfig.numRings (29)`: Represents the number of physical WS2812B LEDs on the spinning arm.
By centralizing these variables, any future hardware changes (like soldering on a longer LED strip) require only changing these two numbers to adapt the entire app's rendering engine.

---

## 2. Image Processing: Cartesian to Polar (`lib/utils/image_processor.dart`)
When a user uploads a standard photo, it must be converted from a Cartesian grid (X/Y coordinates) to a Polar grid (Angle/Radius). 

**The Algorithm:**
1. **Square & Scale**: The image is cropped to a perfect square and scaled down so its pixel diameter matches `2 * numRings + 1` (59x59 pixels).
2. **Polar Iteration**: The code iterates through every possible physical point on the fan (54 Slices × 29 Rings).
3. **Trigonometry Mapping**: For a given slice `sOut` and ring `rOut`, the app calculates its exact Cartesian equivalent using:
   - `theta = sOut * (2 * math.pi / numSlices)`
   - `x = rOut * cos(theta)`
   - `y = rOut * sin(theta)`
4. **Color Extraction**: It fetches the color of the pixel at that calculated `(x, y)` coordinate from the resized image, and writes it into a `54x29` matrix. This raw matrix is what gets sent over Bluetooth.

---

## 3. Dynamic Text Rendering (`lib/patterns.dart` & `lib/utils/digital_font.dart`)
Unlike standard screens that use OS-level fonts, this app contains a custom rendering engine to draw text onto the circular LED array.

**The Font Engine:**
* `digital_font.dart` stores characters as hardcoded 5x7 binary arrays (0s and 1s).
* The `getTextPattern()` method in `patterns.dart` loops through a user's string, maps those 0s and 1s to the physical rings/slices, and assigns them the requested RGB color.

**Dynamic Alignment for Hardware Gaps:**
Because the fan relies on a Hall Effect sensor, the physical moment the magnet triggers causes a very slight visual jump (or gap) at the 359° mark.
* In files like `lib/screens/rpm_screen.dart`, the app dynamically calculates the length of the string being displayed (e.g., "700" is 3 characters, "1200" is 4 characters). 
* It uses modulo math `((PovConfig.numSlices - 1) - rpmDigits * 4) % PovConfig.numSlices` to calculate an exact `startSlice` offset. 
* **The Result**: The app forces the gap between the last letter and the first letter to land *exactly* over the physical magnet zone, rendering the gap entirely invisible to the user.

---

## 4. Bluetooth Transmission Engine (`lib/services/bluetooth_service.dart`)
The `BluetoothService` is the bottleneck of the entire system and required specific engineering to handle the high data throughput reliably.

**Data Packing:**
* A single "frame" consists of 54 packets (one for each slice).
* Each packet is 88 bytes: `[Slice Index Byte] + [29 LEDs * 3 RGB Bytes]`.

**Transmission Protocol:**
* At 54 slices, blasting data "Without Response" causes the ESP32's BLE stack queue to overflow, dropping the last ~1/3 of the image. 
* To guarantee 100% data integrity, the app explicitly sets `withoutResponse: false`. 
* This forces a strict Write-and-Acknowledge loop: The app sends Slice 0, waits for the ESP32 to confirm receipt over the air, then sends Slice 1. While this takes roughly ~800 milliseconds to transmit a full frame, it ensures flawlessly intact images.

**Gamma Correction:**
* Human eyes perceive light logarithmically, but LEDs output light linearly. If you send a "50% brightness" blue (`rgb(0, 0, 128)`), it looks overwhelmingly bright in real life.
* The Bluetooth service intercepts every single RGB value before transmission and passes it through `_gammaTable`.
* `_gammaTable` is a pre-calculated mathematical array using an exponent of `2.8`. It squashes the mid-tones, ensuring the physical LEDs perfectly match the deep, saturated colors seen on the smartphone screen.

---

## 5. View Layer (`lib/screens/pov_tool.dart`, etc.)
The individual screens in the app handle user input, generate the necessary `List<List<int>>` matrices using the logic layers above, and pipe them directly into `bleService.sendPattern()`. 

For example, in the **POV Playground** (`pov_tool.dart`), tapping the screen converts the raw touch coordinate `(x, y)` back into an `(angle, radius)` to color a specific grid block, instantly sending that updated matrix to the ESP32.
