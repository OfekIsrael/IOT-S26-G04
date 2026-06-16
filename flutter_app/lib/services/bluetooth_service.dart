import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'communication_service.dart';

class BluetoothService implements CommunicationService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _modeCharacteristic;
  fbp.BluetoothCharacteristic? _imageCharacteristic;

  // Generic UUIDs to be matched in the ESP32 code later.
  final String serviceUuid = "12345678-1234-1234-1234-123456789012";
  final String modeCharUuid = "87654321-4321-4321-4321-210987654321";
  final String imageCharUuid = "11111111-2222-3333-4444-555555555555";

  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  void setConnectedDevice(fbp.BluetoothDevice device) {
    _connectedDevice = device;
  }

  Future<bool> discoverServices() async {
    if (_connectedDevice == null) return false;
    
    try {
      List<fbp.BluetoothService> services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == modeCharUuid) {
              _modeCharacteristic = characteristic;
            } else if (characteristic.uuid.toString() == imageCharUuid) {
              _imageCharacteristic = characteristic;
            }
          }
        }
      }
      return _modeCharacteristic != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkConnection() async {
    if (_connectedDevice == null) return false;
    return _connectedDevice!.isConnected;
  }

  @override
  Future<bool> setMode(String mode, {Map<String, dynamic>? params}) async {
    if (_modeCharacteristic == null || _connectedDevice == null || !_connectedDevice!.isConnected) {
      return false;
    }

    try {
      final payload = jsonEncode({
        'mode': mode,
        if (params != null) 'params': params,
      });
      await _modeCharacteristic!.write(utf8.encode(payload), withoutResponse: false);
      return true;
    } catch (e) {
      print('Error setting BLE mode: $e');
      return false;
    }
  }

  @override
  Future<bool> sendImageData(List<int> rgbData) async {
    if (_imageCharacteristic == null || _connectedDevice == null || !_connectedDevice!.isConnected) {
      return false;
    }

    try {
      // BLE usually has an MTU limit (often 512 bytes max per write).
      // We must chunk the data if it exceeds the negotiated MTU.
      int mtu = await _connectedDevice!.mtu.first;
      int chunkSize = mtu - 3; // 3 bytes for overhead
      
      for (int i = 0; i < rgbData.length; i += chunkSize) {
        int end = (i + chunkSize < rgbData.length) ? i + chunkSize : rgbData.length;
        List<int> chunk = rgbData.sublist(i, end);
        await _imageCharacteristic!.write(chunk, withoutResponse: true); // withoutResponse is much faster for large streams
      }
      return true;
    } catch (e) {
      print('Error sending BLE image data: $e');
      return false;
    }
  }
}
