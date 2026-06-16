import 'dart:convert';
import 'package:http/http.dart' as http;
import 'communication_service.dart';

class WifiService implements CommunicationService {
  final String baseUrl;

  WifiService({required this.baseUrl});

  /// Pings the ESP32 to check if it is reachable
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      // We ping the root. Even if the ESP32 doesn't have a specific route for '/' 
      // and returns a 404 Not Found, getting a response means it is connected!
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      return true; 
    } catch (e) {
      // Timeouts and SocketExceptions mean it is actually unreachable.
      return false;
    }
  }

  /// Sends a mode change command to the ESP32
  /// e.g., mode = 'clock', 'stopwatch', 'timer'
  Future<bool> setMode(String mode, {Map<String, dynamic>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl/set_mode');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mode': mode,
          if (params != null) 'params': params,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to set mode: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error setting mode: $e');
      return false;
    }
  }

  /// Sends a 1D RGB array (image data) to the ESP32
  Future<bool> sendImageData(List<int> rgbData) async {
    try {
      final uri = Uri.parse('$baseUrl/upload_image');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/octet-stream'},
        body: rgbData,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to send image: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending image: $e');
      return false;
    }
  }
}
