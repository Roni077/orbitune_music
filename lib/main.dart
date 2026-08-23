import 'dart:async';
import 'dart:io';
import 'dart:ui';
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

  // 1. Global asynchronous error boundary
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher Error] $error\n$stack');
    return true;
  };

  // 2. Strict True Edge-to-Edge and Orientation Locking
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Parallelize critical database & audio service initializations
  await Future.wait([
    HiveService.instance.init(),
    OrbituneAudioHandler.initBackgroundService(),
  ]);

  // Non-blocking background filesystem & extractor engine initialization
  unawaited(
    DownloadService.ensureDownloadsDirectoryExists().catchError((e) {
      debugPrint('[main] ensureDownloadsDirectoryExists error: $e');
      return Directory.systemTemp;
    }),
  );

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
