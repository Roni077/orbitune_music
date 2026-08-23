import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _countrySearchController = TextEditingController();
  String _selectedCountry = 'GLOBAL';

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _countrySearchController.dispose();
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
    final searchQuery = _countrySearchController.text.trim().toLowerCase();
    final filteredCountries = CountryRegionSelectionSheet.allCountries.where((c) {
      if (searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(searchQuery) ||
          c.code.toLowerCase().contains(searchQuery) ||
          c.chartDescription.toLowerCase().contains(searchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        12.0,
        AppConstants.horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.globe,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Music Region',
                      style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                    ),
                    Text(
                      'Personalizes charts and discovery mixes',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _countrySearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search country or region...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: _countrySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        setState(() {
                          _countrySearchController.clear();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),

          // Country List
          Expanded(
            child: filteredCountries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.globe, size: 40, color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No country matches "${_countrySearchController.text}"',
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = country.code.toUpperCase() == _selectedCountry.toUpperCase();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCountry = country.code;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: AppConstants.fastAnimation,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.12)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.2)
                                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              country.name,
                                              style: AppTypography.titleMedium.copyWith(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? primaryColor : theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? primaryColor.withValues(alpha: 0.2)
                                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              country.code,
                                              style: AppTypography.caption.copyWith(
                                                color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        country.chartDescription,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  Icon(
                                    LucideIcons.checkCircle2,
                                    color: primaryColor,
                                    size: 20,
                                  )
                                else
                                  Icon(
                                    LucideIcons.circle,
                                    color: theme.colorScheme.outlineVariant,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  final Set<String> _selectedGenres = {'Pop', 'Lo-Fi'};

  static const List<String> _genrePresets = [
    'Pop', 'Hip-Hop', 'EDM', 'Rock', 'Lo-Fi', 'R&B', 'Indie', 'Bollywood', 'Classical'
  ];

  Widget _buildReadyPage() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding * 1.5,
        vertical: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 72,
              color: primary,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'You\'re all set!',
              style: AppTypography.headlineLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 10),
            Text(
              'Select genres you enjoy to seed your discovery mix:',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              children: _genrePresets.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                  showCheckmark: false,
                  avatar: isSelected
                      ? const Icon(LucideIcons.check, size: 14)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
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
