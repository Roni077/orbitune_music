import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/mini_player.dart';
import 'package:orbitune/features/discovery/presentation/screens/home_screen.dart';
import 'package:orbitune/features/library/presentation/screens/library_screen.dart';
import 'package:orbitune/features/search/presentation/screens/search_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/settings_screen.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Screen contents with Lazy IndexedStack to preserve memory and scroll positions
          IndexedStack(
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

          // Floating MiniPlayer and Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Docked / Floating Mini Player (isolated from shell rebuilds)
                  const _DockedMiniPlayerWrapper(),

                  // Floating Navigation Bar
                  CustomBottomNav(
                    currentIndex: _currentIndex,
                    onTabSelected: _onTabSelected,
                  ),
                ],
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: hasTrack ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
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

