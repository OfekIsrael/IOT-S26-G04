abstract class CommunicationService {
  /// Checks if the device is currently reachable/connected
  Future<bool> checkConnection();

  /// Sends a mode change command to the ESP32
  Future<bool> setMode(String mode, {Map<String, dynamic>? params});

  /// Sends image data to the ESP32
  Future<bool> sendImageData(List<int> rgbData);
}
