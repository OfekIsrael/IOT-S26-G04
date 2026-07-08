import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'communication_service.dart';

class BluetoothService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _imageCharacteristic;

  // Match the ESP32 UUIDs
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String imageCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  void setConnectedDevice(fbp.BluetoothDevice device) {
    _connectedDevice = device;
  }

  Future<bool> discoverServices() async {
    if (_connectedDevice == null) return false;
    
    try {
      // Request larger MTU as configured on ESP32
      await _connectedDevice!.requestMtu(512);

      List<fbp.BluetoothService> services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == imageCharUuid) {
              _imageCharacteristic = characteristic;
            }
          }
        }
      }
      return _imageCharacteristic != null;
    } catch (e) {
      print('Discover services error: $e');
      return false;
    }
  }

  Future<bool> checkConnection() async {
    if (_connectedDevice == null) return false;
    return _connectedDevice!.isConnected;
  }

  // Sends 36 packets (one for each slice).
  // Each packet is 88 bytes: [Slice Index (0-35)] + [29 * 3 RGB bytes]
  Future<bool> sendPattern(List<List<int>> patternData) async {
    if (_imageCharacteristic == null || _connectedDevice == null || !_connectedDevice!.isConnected) {
      return false;
    }

    if (patternData.length != 36) {
      print('Invalid pattern size, must be 36 slices.');
      return false;
    }

    try {
      for (int slice = 0; slice < 36; slice++) {
        List<int> sliceData = patternData[slice];
        if (sliceData.length != 29 * 3) {
           print('Invalid slice data size.');
           return false;
        }

        List<int> packet = [slice];
        packet.addAll(sliceData);
        
        // Write the 88 byte packet without response for speed
        await _imageCharacteristic!.write(packet, withoutResponse: true);
        
        // Small delay to prevent overwhelming the ESP32 BLE stack
        await Future.delayed(const Duration(milliseconds: 5));
      }
      return true;
    } catch (e) {
      print('Error sending BLE pattern data: $e');
      return false;
    }
  }
}
