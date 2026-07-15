import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'communication_service.dart';
import '../config.dart';

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

  // Gamma correction table (gamma = 2.8) for NeoPixels
  final List<int> _gammaTable = List.generate(
      256, (i) => (math.pow(i / 255.0, 2.8) * 255.0).round().clamp(0, 255));

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

  // Sends packets (one for each slice).
  // Each packet is: [Slice Index] + [numRings * 3 RGB bytes]
  Future<bool> sendPattern(List<List<int>> patternData) async {
    if (_imageCharacteristic == null || _connectedDevice == null || !_connectedDevice!.isConnected) {
      return false;
    }

    if (patternData.length != PovConfig.numSlices) {
      print('Invalid pattern size, must be ${PovConfig.numSlices} slices.');
      return false;
    }

    try {
      for (int slice = 0; slice < PovConfig.numSlices; slice++) {
        List<int> sliceData = patternData[slice];
        if (sliceData.length != PovConfig.numRings * 3) {
           print('Invalid slice data size.');
           return false;
        }

        List<int> packet = [slice];
        
        // Apply gamma correction to the RGB data
        for (int i = 0; i < sliceData.length; i++) {
          packet.add(_gammaTable[sliceData[i]]);
        }
        
        // Write the 88 byte packet. We use withoutResponse: false to ensure 
        // the ESP32 acknowledges receipt before sending the next packet. 
        // This completely prevents dropping packets when sending large 54-slice arrays!
        await _imageCharacteristic!.write(packet, withoutResponse: false);
        
        // Very small delay (not strictly needed with response, but helps stability)
        await Future.delayed(const Duration(milliseconds: 2));
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
