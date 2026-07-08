import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'communication_service.dart';

class BluetoothService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _imageCharacteristic;
  fbp.BluetoothCharacteristic? _rpmCharacteristic;
  fbp.BluetoothCharacteristic? _brightnessCharacteristic;

  // Match the ESP32 UUIDs
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String imageCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String rpmCharUuid = "d203a55e-a6a9-4673-9a3b-28564a51e605";
  final String brightnessCharUuid = "b4250400-f38b-4a37-b64d-7bcda53f932e";

  // Expose RPM updates directly
  final ValueNotifier<int> rpmNotifier = ValueNotifier<int>(0);

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
            } else if (characteristic.uuid.toString() == rpmCharUuid) {
              _rpmCharacteristic = characteristic;
              // Subscribe to RPM notifications
              if (_rpmCharacteristic!.properties.notify) {
                await _rpmCharacteristic!.setNotifyValue(true);
                _rpmCharacteristic!.lastValueStream.listen((value) {
                  if (value.isNotEmpty) {
                    try {
                      String rpmStr = utf8.decode(value);
                      int rpm = int.tryParse(rpmStr) ?? 0;
                      rpmNotifier.value = rpm;
                    } catch (e) {
                      print('Error parsing RPM: $e');
                    }
                  }
                });
              }
            } else if (characteristic.uuid.toString() == brightnessCharUuid) {
              _brightnessCharacteristic = characteristic;
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

  Future<bool> setBrightness(int brightness) async {
    if (_brightnessCharacteristic == null || _connectedDevice == null || !_connectedDevice!.isConnected) {
      return false;
    }
    try {
      await _brightnessCharacteristic!.write([brightness], withoutResponse: true);
      return true;
    } catch (e) {
      print('Error setting brightness: $e');
      return false;
    }
  }
}
