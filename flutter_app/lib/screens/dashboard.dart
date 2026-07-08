import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../patterns.dart';
import 'bluetooth_scanner.dart';
import 'pov_tool.dart';
import 'clock_screen.dart';
import 'text_screen.dart';
import 'rpm_screen.dart';
import 'weather_screen.dart';
import 'image_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double _brightness = 40.0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POV Display App', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothScannerScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionBanner(ref),
            const SizedBox(height: 24),
            
            // Brightness Slider
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.yellow),
                const SizedBox(width: 8),
                const Text('Brightness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 0,
                    max: 255,
                    divisions: 255,
                    label: _brightness.round().toString(),
                    onChanged: (val) {
                      setState(() => _brightness = val);
                      ref.read(bluetoothServiceProvider).setBrightness(val.toInt());
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Dynamic Modes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _PatternCard(
                    title: 'Live Clock',
                    icon: Icons.access_time_filled,
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ClockScreen()),
                      );
                    },
                  ),
                  _PatternCard(
                    title: 'Custom Text',
                    icon: Icons.text_fields,
                    color: Colors.deepOrangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomTextScreen()),
                      );
                    },
                  ),
                  _PatternCard(
                    title: 'Live RPM',
                    icon: Icons.speed,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RpmScreen()),
                      );
                    },
                  ),
                  _PatternCard(
                    title: 'Live Weather',
                    icon: Icons.cloud,
                    color: Colors.lightBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WeatherScreen()),
                      );
                    },
                  ),
                  _PatternCard(
                    title: 'Upload Image',
                    icon: Icons.image,
                    color: Colors.deepPurpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ImageScreen()),
                      );
                    },
                  ),
                  _PatternCard(
                    title: 'Custom Drawing',
                    icon: Icons.draw,
                    color: Colors.greenAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PolarPlayground()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner(WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);

    return connectionStatus.when(
      data: (isConnected) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isConnected ? Colors.green : Colors.red),
          ),
          child: Row(
            children: [
              Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
                   color: isConnected ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected ? 'Connected to ESP32' : 'Disconnected (Tap Bluetooth icon to connect)',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(connectionStatusProvider),
                tooltip: 'Check Connection',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error checking connection'),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PatternCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
