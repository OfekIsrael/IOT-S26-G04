# Holographic POV Controller App

This is the Flutter companion application for the Holographic POV Display project.

## Features
- **Bluetooth Low Energy (BLE)** automatic scanning and pairing with the ESP32.
- **Image Beaming**: Converts any gallery photo into polar coordinates and transmits it to the fan.
- **Live Weather**: Fetches local weather and displays it as text on the fan.
- **RPM Monitor**: Displays real-time motor speed using the Hall Effect sensor data.
- **POV Playground**: A circular drawing grid that instantly mirrors custom pixel art to the fan.

## Configuration
To match the physical hardware of the fan, you can edit the parameters inside `lib/config.dart`.
If you add more LEDs or change the slice resolution on the physical hardware, simply update the `PovConfig` parameters and rebuild the app.

For full installation and compilation instructions, see the `/Documentation` folder in the root repository.
