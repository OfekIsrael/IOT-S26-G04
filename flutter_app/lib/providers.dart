import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/wifi_service.dart';
import 'services/bluetooth_service.dart';
import 'services/communication_service.dart';

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

// IP Address State
class IpAddressNotifier extends StateNotifier<String> {
  IpAddressNotifier() : super('http://192.168.4.1');

  void setIp(String ip) {
    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      state = 'http://$ip';
    } else {
      state = ip;
    }
  }
}

final ipAddressProvider = StateNotifierProvider<IpAddressNotifier, String>((ref) {
  return IpAddressNotifier();
});

// Wi-Fi Service Provider
final wifiServiceProvider = Provider<WifiService>((ref) {
  final baseUrl = ref.watch(ipAddressProvider);
  return WifiService(baseUrl: baseUrl); 
});

// Bluetooth Service Provider
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  return BluetoothService();
});

enum ConnectionProtocol { wifi, bluetooth }

// Active Protocol State
class ActiveProtocolNotifier extends StateNotifier<ConnectionProtocol> {
  ActiveProtocolNotifier() : super(ConnectionProtocol.wifi);

  void setProtocol(ConnectionProtocol protocol) {
    state = protocol;
  }
}

final activeProtocolProvider = StateNotifierProvider<ActiveProtocolNotifier, ConnectionProtocol>((ref) {
  return ActiveProtocolNotifier();
});

// Unified Communication Service Provider
final communicationServiceProvider = Provider<CommunicationService>((ref) {
  final protocol = ref.watch(activeProtocolProvider);
  if (protocol == ConnectionProtocol.wifi) {
    return ref.watch(wifiServiceProvider);
  } else {
    return ref.watch(bluetoothServiceProvider);
  }
});

// Connection Status Provider
final connectionStatusProvider = FutureProvider<bool>((ref) async {
  final commService = ref.watch(communicationServiceProvider);
  return await commService.checkConnection();
});
