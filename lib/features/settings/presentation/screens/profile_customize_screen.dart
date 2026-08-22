import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Available avatar icon presets for profile personalization
class ProfileAvatarOption {
  final String id;
  final String label;
  final IconData icon;

  const ProfileAvatarOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Profile Customization Studio Screen
class ProfileCustomizeScreen extends ConsumerStatefulWidget {
  const ProfileCustomizeScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileCustomizeScreen()),
    );
  }

  @override
  ConsumerState<ProfileCustomizeScreen> createState() => _ProfileCustomizeScreenState();
}

class _ProfileCustomizeScreenState extends ConsumerState<ProfileCustomizeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  late String _selectedAvatarIcon;
  late int _selectedColorIndex;
  late String _selectedBadge;
  late String _selectedGenre;
  late String _selectedCountry;

  bool _hasUnsavedChanges = false;

  static const List<ProfileAvatarOption> avatarPresets = [
    ProfileAvatarOption(id: 'user', label: 'Classic', icon: LucideIcons.user),
    ProfileAvatarOption(id: 'headphones', label: 'Hi-Fi', icon: LucideIcons.headphones),
    ProfileAvatarOption(id: 'music', label: 'Melody', icon: LucideIcons.music),
    ProfileAvatarOption(id: 'sparkles', label: 'Cosmic', icon: LucideIcons.sparkles),
    ProfileAvatarOption(id: 'disc', label: 'Vinyl', icon: LucideIcons.disc),
    ProfileAvatarOption(id: 'flame', label: 'Hype', icon: LucideIcons.flame),
    ProfileAvatarOption(id: 'heart', label: 'Soul', icon: LucideIcons.heart),
    ProfileAvatarOption(id: 'zap', label: 'Electro', icon: LucideIcons.zap),
    ProfileAvatarOption(id: 'rocket', label: 'Voyager', icon: LucideIcons.rocket),
    ProfileAvatarOption(id: 'star', label: 'Star', icon: LucideIcons.star),
    ProfileAvatarOption(id: 'radio', label: 'Retro', icon: LucideIcons.radio),
    ProfileAvatarOption(id: 'mic', label: 'Vocal', icon: LucideIcons.mic),
  ];

  static const List<String> personaBadges = [
    'Hi-Fi',
    'Audiophile',
    'Cosmic Voyager',
    'Bass Booster',
    'Vinyl Purist',
    'Night Owl',
    'Lo-Fi Dreamer',
    'Indie Soul',
  ];

  static const List<String> musicGenres = [
    'All-Rounder',
    'Electronic / EDM',
    'Hip-Hop & Rap',
    'Rock & Metal',
    'Pop & Hits',
    'Lo-Fi & Chill',
    'Indie & Folk',
    'Bengali & Regional',
    'Jazz & Blues',
    'R&B & Soul',
    'Classical & Ambient',
  ];

  static const List<String> countryList = [
    'US', 'IN', 'GB', 'CA', 'AU', 'DE', 'JP', 'BR', 'FR', 'IT',
    'ES', 'MX', 'KR', 'ZA', 'NG', 'AR', 'ID', 'TR', 'SA', 'Global',
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.username ?? 'Orbitune Listener');
    _bioController = TextEditingController(text: settings.bio ?? 'Listening on Orbitune');
    _selectedAvatarIcon = settings.avatarIcon;
    _selectedColorIndex = (settings.avatarColorIndex >= 0 &&
            settings.avatarColorIndex < AppColors.accentPalette.length)
        ? settings.avatarColorIndex
        : 0;
    _selectedBadge = settings.profileBadge;
    _selectedGenre = settings.favoriteGenre ?? 'All-Rounder';
    _selectedCountry = settings.contentCountry;

    _nameController.addListener(_markChanged);
    _bioController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  IconData _getIconData(String id) {
    return avatarPresets
        .firstWhere((preset) => preset.id == id, orElse: () => avatarPresets.first)
        .icon;
  }

  Future<void> _saveProfile() async {
    final cleanName = _nameController.text.trim().isEmpty
        ? 'Orbitune Listener'
        : _nameController.text.trim();
    final cleanBio = _bioController.text.trim().isEmpty
        ? 'Listening on Orbitune'
        : _bioController.text.trim();

    await ref.read(settingsProvider.notifier).updateProfile(
          username: cleanName,
          bio: cleanBio,
          avatarIcon: _selectedAvatarIcon,
          avatarColorIndex: _selectedColorIndex,
          profileBadge: _selectedBadge,
          favoriteGenre: _selectedGenre,
          country: _selectedCountry,
        );

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(LucideIcons.checkCircle2, color: AppColors.accentGreen, size: 20),
              SizedBox(width: 10),
              Text('Profile customized and saved successfully!'),
            ],
          ),
          backgroundColor: AppColors.darkSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _nameController.text = 'Orbitune Listener';
      _bioController.text = 'Listening on Orbitune';
      _selectedAvatarIcon = 'user';
      _selectedColorIndex = 0;
      _selectedBadge = 'Hi-Fi';
      _selectedGenre = 'All-Rounder';
      _selectedCountry = 'US';
      _hasUnsavedChanges = true;
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.globe, color: AppColors.accentCyan),
                      const SizedBox(width: 12),
                      Text('Select Discovery Region', style: AppTypography.titleMedium),
                    ],
                  ),
                ),
                const Divider(color: AppColors.glassBorder),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: countryList.length,
                    itemBuilder: (context, index) {
                      final country = countryList[index];
                      final isSelected = country == _selectedCountry;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentCyan.withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          country,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(LucideIcons.check, color: AppColors.accentCyan, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _hasUnsavedChanges = true;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = (_isIndexValid(_selectedColorIndex))
        ? AppColors.accentPalette[_selectedColorIndex]
        : AppColors.accentGreen;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile & Persona', style: AppTypography.brandTitle),
        actions: [
          if (_hasUnsavedChanges)
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: activeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. LIVE PROFILE HEADER PREVIEW
          _buildLiveProfilePreview(activeAccent),
          const SizedBox(height: 24),

          // 2. AVATAR ICON SELECTOR
          _buildSectionHeader('Avatar Icon Preset'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose an icon that defines your musical identity',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _buildAvatarGrid(activeAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. AVATAR COLOR PALETTE
          _buildSectionHeader('Avatar Glow & Color Theme'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select the primary accent gradient for your avatar and badges',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _buildColorPalettePicker(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. DISPLAY NAME & BIO
          _buildSectionHeader('Profile Identity'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display Name',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  maxLength: 30,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your name or handle',
                    prefixIcon: const Icon(LucideIcons.user, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.darkBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: activeAccent, width: 1.5),
                    ),
                    counterStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bio / Status Quote',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioController,
                  maxLength: 80,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. Lost in lo-fi beats • Audiophile explorer',
                    prefixIcon: const Icon(LucideIcons.quote, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.darkBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: activeAccent, width: 1.5),
                    ),
                    counterStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. MUSIC PERSONA BADGE
          _buildSectionHeader('Music Persona Badge'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showcase your music listening style on your profile',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: personaBadges.map((badge) {
                    final isSelected = badge == _selectedBadge;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(badge),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: AppColors.darkBackground.withValues(alpha: 0.6),
                      selectedColor: activeAccent,
                      checkmarkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isSelected ? activeAccent : AppColors.glassBorder,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedBadge = badge;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. FAVORITE MUSIC GENRE
          _buildSectionHeader('Primary Vibe / Favorite Genre'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tailors quick recommendations and home discovery chips',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: musicGenres.map((genre) {
                    final isSelected = genre == _selectedGenre;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(genre),
                      labelStyle: TextStyle(
                        color: isSelected ? activeAccent : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: AppColors.darkBackground.withValues(alpha: 0.5),
                      selectedColor: activeAccent.withValues(alpha: 0.18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? activeAccent : AppColors.glassBorder,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGenre = genre;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 7. REGION & DISCOVERY LOCATION
          _buildSectionHeader('Region & Discovery Preferences'),
          _buildCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.globe, color: AppColors.accentCyan, size: 20),
              ),
              title: Text('Discovery Country / Region', style: AppTypography.titleSmall),
              subtitle: Text(
                'Current: $_selectedCountry • Affects top charts and trending tracks',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: activeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry,
                      style: AppTypography.labelMedium.copyWith(
                        color: activeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
              onTap: _showCountryPicker,
            ),
          ),
          const SizedBox(height: 28),

          // 8. SAVE & RESET BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: const Text('Reset Defaults'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: activeAccent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  bool _isIndexValid(int index) {
    return index >= 0 && index < AppColors.accentPalette.length;
  }

  Widget _buildLiveProfilePreview(Color accent) {
    final username = _nameController.text.trim().isEmpty
        ? 'Orbitune Listener'
        : _nameController.text.trim();
    final bio = _bioController.text.trim().isEmpty
        ? 'Listening on Orbitune'
        : _bioController.text.trim();
    final iconData = _getIconData(_selectedAvatarIcon);

    return ExpressiveCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(26),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.75),
      child: Column(
        children: [
          // Live Avatar with glowing multi-layer gradient
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.65),
                        AppColors.darkSurfaceElevated,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),

          // User Name & Badge
          Text(
            username,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Persona Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.award, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  _selectedBadge.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bio Quote
          Text(
            '"$bio"',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Region and Genre tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.globe, size: 12, color: AppColors.accentCyan),
                    const SizedBox(width: 5),
                    Text(
                      _selectedCountry,
                      style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.music2, size: 12, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      _selectedGenre,
                      style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(Color accent) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: avatarPresets.length,
      itemBuilder: (context, index) {
        final preset = avatarPresets[index];
        final isSelected = preset.id == _selectedAvatarIcon;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedAvatarIcon = preset.id;
              _hasUnsavedChanges = true;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: AppConstants.fastAnimation,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.2)
                  : AppColors.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accent : AppColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  preset.icon,
                  size: 26,
                  color: isSelected ? accent : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  preset.label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? accent : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPalettePicker() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.accentPalette.length,
        itemBuilder: (context, index) {
          final color = AppColors.accentPalette[index];
          final isSelected = index == _selectedColorIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColorIndex = index;
                  _hasUnsavedChanges = true;
                });
              },
              child: AnimatedContainer(
                duration: AppConstants.fastAnimation,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.6 : 0.25),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(LucideIcons.check, size: 20, color: Colors.black),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return ExpressiveCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.55),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
