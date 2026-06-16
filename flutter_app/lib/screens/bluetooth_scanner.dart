import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers.dart';

class BluetoothScannerScreen extends ConsumerStatefulWidget {
  const BluetoothScannerScreen({super.key});

  @override
  ConsumerState<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends ConsumerState<BluetoothScannerScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    // Request Bluetooth and Location permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions are required')),
        );
      }
    }
  }

  void _startScan() {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to ${device.platformName}...')),
      );
    }

    try {
      await device.connect();
      final bleService = ref.read(bluetoothServiceProvider);
      bleService.setConnectedDevice(device);
      
      bool servicesFound = await bleService.discoverServices();
      
      if (mounted) {
        if (servicesFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connected & Ready!'), backgroundColor: Colors.green),
          );
          ref.refresh(connectionStatusProvider);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connected, but correct services not found'), backgroundColor: Colors.orange),
          );
          device.disconnect();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to POV LED'),
        actions: [
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _scanResults.isEmpty && !_isScanning
          ? const Center(child: Text('No devices found.'))
          : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                final deviceName = result.device.platformName.isNotEmpty ? result.device.platformName : 'Unknown Device';
                
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(deviceName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(result.device),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
    );
  }
}
