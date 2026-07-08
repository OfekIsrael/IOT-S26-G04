import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../patterns.dart';
import 'bluetooth_scanner.dart';
import 'pov_tool.dart';
import 'clock_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const Text(
              'Predefined Patterns',
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
                  _PatternCard(
                    title: 'Rainbow Spiral',
                    icon: Icons.cyclone,
                    color: Colors.purpleAccent,
                    onTap: () => _sendPattern(context, ref, 'Spiral', PredefinedPatterns.getSpiralPattern()),
                  ),
                  _PatternCard(
                    title: 'Concentric Rings',
                    icon: Icons.radar,
                    color: Colors.blueAccent,
                    onTap: () => _sendPattern(context, ref, 'Rings', PredefinedPatterns.getRingsPattern()),
                  ),
                  _PatternCard(
                    title: 'Yellow Star',
                    icon: Icons.star,
                    color: Colors.orangeAccent,
                    onTap: () => _sendPattern(context, ref, 'Star', PredefinedPatterns.getStarPattern()),
                  ),
                  _PatternCard(
                    title: 'Red Fill',
                    icon: Icons.format_color_fill,
                    color: Colors.redAccent,
                    onTap: () => _sendPattern(context, ref, 'Red', PredefinedPatterns.getSolidPattern(255, 0, 0)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendPattern(BuildContext context, WidgetRef ref, String name, List<List<int>> patternData) async {
    final bleService = ref.read(bluetoothServiceProvider);
    
    // UI feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending $name pattern...')),
    );

    bool success = await bleService.sendPattern(patternData);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$name sent successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to send. Check Bluetooth connection.'),
              backgroundColor: Colors.red),
        );
      }
    }
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
