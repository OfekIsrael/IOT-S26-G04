import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/bluetooth_service.dart';

// Theme Mode State
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
  
  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Bluetooth Service Provider
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  return BluetoothService();
});

// Connection Status Provider
final connectionStatusProvider = FutureProvider<bool>((ref) async {
  final commService = ref.watch(bluetoothServiceProvider);
  return await commService.checkConnection();
});
