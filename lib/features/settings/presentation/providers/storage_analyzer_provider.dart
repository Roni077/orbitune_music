import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/settings/data/storage_analyzer_service.dart';

/// Provider for StorageAnalyzerService instance
final storageAnalyzerServiceProvider = Provider<StorageAnalyzerService>((ref) {
  return const StorageAnalyzerService();
});

/// StateNotifier providing real-time storage statistics for Orbitune
class StorageStatsNotifier extends StateNotifier<StorageStats> {
  final StorageAnalyzerService _service;
  final Ref _ref;

  StorageStatsNotifier({
    required StorageAnalyzerService service,
    required Ref ref,
  })  : _service = service,
        _ref = ref,
        super(const StorageStats(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await refresh();

    // Auto-recalculate when offline downloads change (new download or deletion)
    _ref.listen(downloadListProvider, (previous, next) {
      if (previous?.length != next.length) {
        refresh();
      }
    });
  }

  /// Recalculates storage usage across all physical directories in real time
  Future<void> refresh() async {
    try {
      final stats = await _service.analyzeStorage();
      if (mounted) {
        state = stats;
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

/// Riverpod provider for reactive StorageStats
final storageStatsProvider =
    StateNotifierProvider<StorageStatsNotifier, StorageStats>((ref) {
  final service = ref.watch(storageAnalyzerServiceProvider);
  return StorageStatsNotifier(service: service, ref: ref);
});
