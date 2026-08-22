import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/settings/presentation/dialogs/audio_quality_selection_dialog.dart';
import 'package:orbitune/features/settings/presentation/dialogs/country_region_dialog.dart';
import 'package:orbitune/features/settings/presentation/dialogs/language_selection_dialog.dart';
import 'package:orbitune/features/settings/presentation/dialogs/lyrics_provider_dialog.dart';

void main() {
  group('Material 3 Expressive Selection Dialogs & Sheets Tests', () {
    testWidgets('AudioQualitySelectionSheet renders streaming qualities and handles selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      AudioQuality? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AudioQualitySelectionSheet.show(
                    context,
                    currentQuality: AudioQuality.high320k,
                    onQualitySelected: (q) => selected = q,
                    isDownload: false,
                  );
                },
                child: const Text('Open Streaming Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Streaming Dialog'));
      await tester.pumpAndSettle();

      // Verify header & titles
      expect(find.text('Streaming Quality'), findsOneWidget);
      expect(find.text('Lossless Studio Audio'), findsOneWidget);
      expect(find.text('Ultra High Definition'), findsOneWidget);
      expect(find.text('High Definition'), findsOneWidget);
      expect(find.text('Data Saver'), findsOneWidget);

      // Verify badges
      expect(find.text('FLAC 1411k'), findsOneWidget);
      expect(find.text('320 KBPS'), findsOneWidget);

      // Tap Lossless option
      await tester.tap(find.widgetWithText(ExpressiveCard, 'Lossless Studio Audio'));
      await tester.pumpAndSettle();

      expect(selected, AudioQuality.lossless);
    });

    testWidgets('AudioQualitySelectionSheet renders download quality mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      AudioQuality? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AudioQualitySelectionSheet.show(
                    context,
                    currentQuality: AudioQuality.high320k,
                    onQualitySelected: (q) => selected = q,
                    isDownload: true,
                  );
                },
                child: const Text('Open Download Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Download Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Download Quality'), findsOneWidget);
      expect(find.text('~35 MB / song'), findsOneWidget);
      expect(find.text('~8 MB / song'), findsOneWidget);

      await tester.tap(find.widgetWithText(ExpressiveCard, 'Data Saver'));
      await tester.pumpAndSettle();

      expect(selected, AudioQuality.low96k);
    });

    testWidgets('CountryRegionSelectionSheet searches, filters, and selects country',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      String? selectedCode;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CountryRegionSelectionSheet.show(
                    context,
                    currentCountryCode: 'US',
                    onCountrySelected: (code) => selectedCode = code,
                  );
                },
                child: const Text('Open Region Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Region Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Music Country & Region'), findsOneWidget);
      expect(find.text('Global Worldwide'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);

      // Search for Japan
      await tester.enterText(find.byType(TextField), 'Japan');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ExpressiveCard, 'Japan'), findsOneWidget);
      expect(find.widgetWithText(ExpressiveCard, 'United States'), findsNothing);

      // Select Japan
      await tester.tap(find.widgetWithText(ExpressiveCard, 'Japan'));
      await tester.pumpAndSettle();

      expect(selectedCode, 'JP');
    });

    testWidgets('LanguageSelectionSheet searches and selects language',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      String? selectedLang;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LanguageSelectionSheet.show(
                    context,
                    currentLanguageCode: 'en',
                    onLanguageSelected: (lang) => selectedLang = lang,
                  );
                },
                child: const Text('Open Language Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Language Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('App Interface Language'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);

      // Search for Japanese
      await tester.enterText(find.byType(TextField), '日本語');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ExpressiveCard, '日本語'), findsOneWidget);
      expect(find.widgetWithText(ExpressiveCard, 'Español'), findsNothing);

      // Select Japanese
      await tester.tap(find.widgetWithText(ExpressiveCard, '日本語'));
      await tester.pumpAndSettle();

      expect(selectedLang, 'ja');
    });

    testWidgets('LyricsProviderSelectionSheet displays providers and features',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      String? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LyricsProviderSelectionSheet.show(
                    context,
                    currentProviderKey: 'lrclib',
                    onProviderSelected: (src) => selectedSource = src,
                  );
                },
                child: const Text('Open Lyrics Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Lyrics Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Lyrics & Metadata Engine'), findsOneWidget);
      expect(find.text('LRCLIB Cloud Lyrics'), findsOneWidget);
      expect(find.text('Embedded Tags & Local LRC'), findsOneWidget);
      expect(find.text('Genius & NetEase Cloud'), findsOneWidget);
      expect(find.text('Orbitune AI Neural Timecoder'), findsOneWidget);

      // Verify feature tags
      expect(find.text('Word-by-Word Sync'), findsOneWidget);
      expect(find.text('100% Offline'), findsOneWidget);
      expect(find.text('Romanization'), findsOneWidget);

      // Select Embedded Tags
      await tester.tap(find.widgetWithText(ExpressiveCard, 'Embedded Tags & Local LRC'));
      await tester.pumpAndSettle();

      expect(selectedSource, 'embedded');
    });
  });
}
