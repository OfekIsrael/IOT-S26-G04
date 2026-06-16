import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'screens/dashboard.dart';
import 'providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PovLedApp(),
    ),
  );
}

class PovLedApp extends ConsumerWidget {
  const PovLedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'POV LED Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const DashboardScreen(),
    );
  }
}
