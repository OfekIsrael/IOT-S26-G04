import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'image_mode.dart';
import 'bluetooth_scanner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POV LED Controller',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              final activeProtocol = ref.read(activeProtocolProvider);
              if (activeProtocol == ConnectionProtocol.wifi) {
                _showIpSettingsDialog(context, ref);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothScannerScreen()));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProtocolSelector(ref)),
            const SizedBox(height: 12),
            _buildConnectionBanner(ref),
            const SizedBox(height: 20),
            const Text(
              'Select Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ModeCard(
                    title: 'Clock',
                    icon: Icons.access_time,
                    color: Colors.blueAccent,
                    onTap: () => _setMode(context, ref, 'clock'),
                  ),
                  _ModeCard(
                    title: 'Stopwatch',
                    icon: Icons.timer,
                    color: Colors.orangeAccent,
                    onTap: () => _setMode(context, ref, 'stopwatch'),
                  ),
                  _ModeCard(
                    title: 'Timer',
                    icon: Icons.hourglass_bottom,
                    color: Colors.pinkAccent,
                    onTap: () => _setMode(context, ref, 'timer'),
                  ),
                  _ModeCard(
                    title: 'Image Mode',
                    icon: Icons.image,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ImageModeScreen()),
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

  void _setMode(BuildContext context, WidgetRef ref, String mode) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Setting mode to $mode...')),
    );

    final commService = ref.read(communicationServiceProvider);
    bool success = await commService.setMode(mode);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Mode $mode activated!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to connect to ESP32'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildConnectionBanner(WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final activeProtocol = ref.watch(activeProtocolProvider);
    final ipAddress = ref.watch(ipAddressProvider);

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
              Icon(isConnected ? (activeProtocol == ConnectionProtocol.wifi ? Icons.wifi : Icons.bluetooth_connected) 
                               : (activeProtocol == ConnectionProtocol.wifi ? Icons.wifi_off : Icons.bluetooth_disabled), 
                   color: isConnected ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected 
                    ? 'Connected to ESP32' 
                    : 'Disconnected (${activeProtocol == ConnectionProtocol.wifi ? ipAddress : 'No Device'})',
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

  Widget _buildProtocolSelector(WidgetRef ref) {
    final activeProtocol = ref.watch(activeProtocolProvider);
    return SegmentedButton<ConnectionProtocol>(
      segments: const [
        ButtonSegment(
          value: ConnectionProtocol.wifi,
          icon: Icon(Icons.wifi),
          label: Text('Wi-Fi'),
        ),
        ButtonSegment(
          value: ConnectionProtocol.bluetooth,
          icon: Icon(Icons.bluetooth),
          label: Text('Bluetooth'),
        ),
      ],
      selected: {activeProtocol},
      onSelectionChanged: (Set<ConnectionProtocol> newSelection) {
        ref.read(activeProtocolProvider.notifier).setProtocol(newSelection.first);
        ref.refresh(connectionStatusProvider);
      },
    );
  }

  void _showIpSettingsDialog(BuildContext context, WidgetRef ref) {
    final ipController = TextEditingController(text: ref.read(ipAddressProvider));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connection Settings'),
          content: TextField(
            controller: ipController,
            decoration: const InputDecoration(
              labelText: 'ESP32 IP Address',
              hintText: 'http://192.168.4.1',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(ipAddressProvider.notifier).setIp(ipController.text);
                ref.refresh(connectionStatusProvider);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
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
                color.withValues(alpha: 0.7),
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
