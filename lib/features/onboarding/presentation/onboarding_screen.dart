import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/settings/presentation/dialogs/country_region_dialog.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final TextEditingController _usernameController = TextEditingController();
  String _selectedCountry = 'GLOBAL';

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: AppConstants.standardAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final username = _usernameController.text.trim().isEmpty 
        ? 'Music Lover' 
        : _usernameController.text.trim();
        
    await ref.read(settingsProvider.notifier).setOnboardingData(
      hasCompletedOnboarding: true,
      username: username,
      country: _selectedCountry,
    );
    // Navigation is handled automatically by the reactive state in app.dart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildPermissionsPage(),
                  _buildUsernamePage(),
                  _buildCountryPage(),
                  _buildReadyPage(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.music,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            'Welcome to Orbitune',
            style: AppTypography.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Your modern, beautiful, and highly expressive music player. Let\'s get you set up.',
            style: AppTypography.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: 80,
            color: Theme.of(context).colorScheme.secondary,
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            'Optimize Your Experience',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To enjoy uninterrupted music playback in the background and control it from your lock screen, we highly recommend enabling these permissions.',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () async {
              final status = await Permission.notification.request();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(status.isGranted ? 'Notifications Allowed!' : 'Notifications Denied'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.bell),
            label: const Text('Allow Notifications'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: const RoundedRectangleBorder(
                borderRadius: AppConstants.roundedLarge,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              final status = await Permission.ignoreBatteryOptimizations.request();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(status.isGranted ? 'Battery Restrictions Ignored!' : 'Battery Optimization unchanged'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.batteryCharging),
            label: const Text('Ignore Battery Restrictions'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: const RoundedRectangleBorder(
                borderRadius: AppConstants.roundedLarge,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Text(
            'You can also do this later in settings.',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildUsernamePage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.userCircle,
            size: 80,
            color: Theme.of(context).colorScheme.tertiary,
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            'What should we call you?',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'e.g. Music Lover',
              border: OutlineInputBorder(
                borderRadius: AppConstants.roundedLarge,
              ),
              prefixIcon: const Icon(LucideIcons.user),
              filled: true,
            ),
            style: AppTypography.bodyLarge,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildCountryPage() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final selectedCountryInfo = CountryRegionSelectionSheet.allCountries.firstWhere(
      (c) => c.code.toUpperCase() == _selectedCountry.toUpperCase(),
      orElse: () => CountryRegionSelectionSheet.allCountries.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding * 2,
        vertical: 16.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              LucideIcons.globe,
              color: primaryColor,
              size: 40,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Choose Music Region',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            'Personalizes your top charts, trending releases, and regional discovery mixes.',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),

          // Selected Country Interactive Card
          InkWell(
            onTap: () {
              CountryRegionSelectionSheet.show(
                context,
                currentCountryCode: _selectedCountry,
                onCountrySelected: (code) {
                  setState(() {
                    _selectedCountry = code;
                  });
                },
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        selectedCountryInfo.flag,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                selectedCountryInfo.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                selectedCountryInfo.code,
                                style: AppTypography.caption.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedCountryInfo.chartDescription,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // Direct Bottom Sheet Button
          FilledButton.tonalIcon(
            onPressed: () {
              CountryRegionSelectionSheet.show(
                context,
                currentCountryCode: _selectedCountry,
                onCountrySelected: (code) {
                  setState(() {
                    _selectedCountry = code;
                  });
                },
              );
            },
            icon: const Icon(LucideIcons.mapPin, size: 18),
            label: const Text('Change Country / Region'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            style: AppTypography.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Dive in and start exploring millions of tracks.',
            style: AppTypography.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots indicator
          Row(
            children: List.generate(5, (index) {
              return AnimatedContainer(
                duration: AppConstants.fastAnimation,
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppConstants.roundedPill,
                ),
              );
            }),
          ),
          
          // Next / Get Started button
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: AppConstants.roundedLarge,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentPage == 4 ? 'Get Started' : 'Next'),
                if (_currentPage < 4) ...[
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 18),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
