import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
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

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToSearch() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _navigateToSettings() {
    setState(() {
      _currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final hasTrack = currentTrack != null;

    final screens = [
      HomeScreen(
        onSearchTap: _navigateToSearch,
        onSettingsTap: _navigateToSettings,
      ),
      const SearchScreen(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Screen contents with IndexedStack to preserve scroll positions
          IndexedStack(
            index: _currentIndex,
            children: screens,
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
                  // Docked / Floating Mini Player
                  AnimatedSlide(
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
                  ),

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

