import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../providers/audio_provider.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Use mounted check to ensure widget is still active
      if (!mounted) return;

      final quranProvider = context.read<QuranProvider>();
      final audioProvider = context.read<AudioProvider>();

      // Suppress notifications during initial loading
      quranProvider.suppressNotifications(true);

      await Future.wait([
        quranProvider.loadSurahs(),
        quranProvider.loadReciters(),
        audioProvider.initialize(),
      ]);

      // Re-enable notifications and notify once
      quranProvider.suppressNotifications(false);
      quranProvider.notifyListeners();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('App initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Continue even if initialization fails
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child; // Show the app immediately, data loads in background
  }
}
