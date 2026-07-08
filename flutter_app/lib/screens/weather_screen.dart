import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../providers.dart';
import '../patterns.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  Timer? _timer;
  bool _isLoading = true;
  bool _isSending = false;
  String _currentTemp = "--";
  Color _selectedColor = Colors.lightBlueAccent;

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndSend();
    // Refresh weather every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchWeatherAndSend();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeatherAndSend() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Get Location Permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // 2. Get Location
      Position position = await Geolocator.getCurrentPosition();

      // 3. Fetch Weather from Open-Meteo
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = (data['current_weather']['temperature'] as num).round();
        
        if (mounted) {
          setState(() {
            _currentTemp = "$temp°C";
            _isLoading = false;
          });
          _sendWeatherFrame();
        }
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      if (mounted) {
        setState(() {
          _currentTemp = "ERR";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendWeatherFrame() async {
    if (_isSending || _currentTemp == "ERR" || _currentTemp == "--") return;
    
    final bleService = ref.read(bluetoothServiceProvider);
    if (bleService.connectedDevice == null) return;

    _isSending = true;
    try {
      int r = (_selectedColor.r * 255.0).round().clamp(0, 255);
      int g = (_selectedColor.g * 255.0).round().clamp(0, 255);
      int b = (_selectedColor.b * 255.0).round().clamp(0, 255);
      
      final matrix = PredefinedPatterns.getTextPattern(_currentTemp, r, g, b);
      await bleService.sendPattern(matrix);
    } finally {
      if (mounted) {
        _isSending = false;
      }
    }
  }

  void _showColorPicker() {
    Color pickerColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick text color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => _selectedColor = pickerColor);
                Navigator.of(context).pop();
                _sendWeatherFrame(); // Resend with new color
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Live Weather Display'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_queue, size: 100, color: Colors.lightBlueAccent),
            const SizedBox(height: 30),
            
            _isLoading 
              ? const CircularProgressIndicator()
              : Text(
                  _currentTemp,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                
            const SizedBox(height: 10),
            Text(
              "Syncing outside temperature using GPS.",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Text Color: ', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                        "Updating POV display...",
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
