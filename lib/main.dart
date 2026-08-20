import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/hive_service.dart';
import 'features/audio_player/data/audio_handler.dart';
import 'features/downloader/data/extractor_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark status and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive Local Database
  await HiveService.instance.init();

  // Initialize Background Audio & Media Notification Service
  await OrbituneAudioHandler.initBackgroundService();

  // Pre-initialize Extractor engine (logs availability for diagnostics)
  final extractorReady = await ExtractorService.instance.initialize().catchError((_) => false);
  debugPrint('[main] ExtractorService available: $extractorReady');

  runApp(
    const ProviderScope(
      child: OrbituneApp(),
    ),
  );
}
