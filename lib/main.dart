import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/hive_service.dart';
import 'features/audio_player/data/audio_handler.dart';
import 'features/downloader/data/download_service.dart';
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

  // Ensure offline downloads folder exists (/storage/emulated/0/Download/Orbitune_Downloads)
  try {
    await DownloadService.ensureDownloadsDirectoryExists();
  } catch (e) {
    debugPrint('[main] ensureDownloadsDirectoryExists error: $e');
  }

  // Initialize Background Audio & Media Notification Service
  await OrbituneAudioHandler.initBackgroundService();

  // Asynchronously initialize Extractor engine in background (non-blocking for app launch)
  unawaited(
    ExtractorService.instance.initialize().then((ready) {
      debugPrint('[main] ExtractorService available: $ready');
    }).catchError((e) {
      debugPrint('[main] ExtractorService init suppressed warning: $e');
    }),
  );

  runApp(
    const ProviderScope(
      child: OrbituneApp(),
    ),
  );
}
