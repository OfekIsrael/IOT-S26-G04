import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../patterns.dart';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Send the initial clock frame immediately
    _sendClockFrame();
    
    // Start a timer to update the clock every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _sendClockFrame();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendClockFrame() async {
    if (_isSending) return; // Prevent overlapping sends
    
    final bleService = ref.read(bluetoothServiceProvider);
    
    // Don't try to send if not connected
    if (bleService.connectedDevice == null) return;

    _isSending = true;
    try {
      final matrix = PredefinedPatterns.getDigitalClockPattern(_currentTime);
      await bleService.sendPattern(matrix);
    } finally {
      if (mounted) {
        _isSending = false;
      }
    }
  }

  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Live Clock Sync'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_later_outlined, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 30),
            Text(
              _formatTime(_currentTime),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Keep this screen open to sync the POV display.",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 40),
            connectionStatus.when(
              data: (isConnected) {
                if (isConnected) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Syncing with ESP32 via BLE...",
                        style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    "Device Disconnected.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text("Error checking connection status", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
