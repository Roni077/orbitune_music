import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/mini_player.dart';
import 'package:orbitune/features/discovery/presentation/screens/home_screen.dart';
import 'package:orbitune/features/library/presentation/screens/library_screen.dart';
import 'package:orbitune/features/search/presentation/screens/search_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/settings_screen.dart';

/// Provider exposing calculated bottom floating dock height (MiniPlayer + Nav + Insets)
final bottomDockHeightProvider = Provider<double>((ref) {
  final hasTrack = ref.watch(currentTrackProvider.select((t) => t != null));
  final miniPlayerH = hasTrack ? (AppConstants.miniPlayerHeight + 6.0) : 0.0;
  return AppConstants.bottomNavHeight + miniPlayerH + 20.0;
});

/// Persistent Root Navigation Shell with M3 Expressive floating bottom nav & docked MiniPlayer
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  final Set<int> _activatedTabs = {0};

  void _onTabSelected(int index) {
    if (!_activatedTabs.contains(index)) {
      setState(() {
        _activatedTabs.add(index);
        _currentIndex = index;
      });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToSettings() {
    _onTabSelected(3);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Screen contents with Lazy IndexedStack to preserve memory and scroll positions
          RepaintBoundary(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _activatedTabs.contains(0)
                    ? HomeScreen(onSettingsTap: _navigateToSettings)
                    : const SizedBox.shrink(),
                _activatedTabs.contains(1)
                    ? const SearchScreen()
                    : const SizedBox.shrink(),
                _activatedTabs.contains(2)
                    ? const LibraryScreen()
                    : const SizedBox.shrink(),
                _activatedTabs.contains(3)
                    ? const SettingsScreen()
                    : const SizedBox.shrink(),
              ],
            ),
          ),

          // Floating MiniPlayer and Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: isKeyboardOpen ? const Offset(0, 1.2) : Offset.zero,
              duration: const Duration(milliseconds: 260),
              curve: Curves.fastOutSlowIn,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Docked / Floating Mini Player (isolated from shell rebuilds)
                    const RepaintBoundary(child: _DockedMiniPlayerWrapper()),

                    // Floating Navigation Bar
                    RepaintBoundary(
                      child: CustomBottomNav(
                        currentIndex: _currentIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated wrapper for Docked MiniPlayer animation and visibility
class _DockedMiniPlayerWrapper extends ConsumerWidget {
  const _DockedMiniPlayerWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrack = ref.watch(currentTrackProvider.select((t) => t != null));

    return AnimatedSlide(
      offset: hasTrack ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 320),
      curve: const SpringCurve(),
      child: AnimatedOpacity(
        opacity: hasTrack ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: hasTrack
            ? const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: MiniPlayer(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class SpringCurve extends Curve {
  const SpringCurve();
  @override
  double transformInternal(double t) {
    return (1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)) + 0.05 * (1.0 - t) * (1.0 - t) * t;
  }
}

