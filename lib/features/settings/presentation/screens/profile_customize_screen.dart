import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/user_avatar.dart';
import 'package:orbitune/features/settings/presentation/dialogs/country_region_dialog.dart';
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
  String? _customAvatarPath;
  bool _customAvatarRemoved = false;
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
    _customAvatarPath = settings.customAvatarPath;
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

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
        final targetPath = '${appDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await File(picked.path).copy(targetPath);
        setState(() {
          _customAvatarPath = savedFile.path;
          _customAvatarRemoved = false;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
        final targetPath = '${appDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await File(picked.path).copy(targetPath);
        setState(() {
          _customAvatarPath = savedFile.path;
          _customAvatarRemoved = false;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeCustomAvatar() {
    setState(() {
      _customAvatarPath = null;
      _customAvatarRemoved = true;
      _hasUnsavedChanges = true;
    });
  }

  void _showImageSourcePicker(Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Profile Picture Source',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.image, color: accent, size: 20),
                ),
                title: const Text('Choose from Local Storage / Gallery'),
                subtitle: const Text('Select a photo from device files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.camera, color: AppColors.accentCyan, size: 20),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhotoWithCamera();
                },
              ),
              if (_customAvatarPath != null && !_customAvatarRemoved)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trash2, color: AppColors.accentPink, size: 20),
                  ),
                  title: const Text('Remove Custom Photo'),
                  subtitle: const Text('Revert to icon preset'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeCustomAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
          customAvatarPath: _customAvatarPath,
          clearCustomAvatar: _customAvatarRemoved || _customAvatarPath == null,
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
      _customAvatarPath = null;
      _customAvatarRemoved = true;
      _selectedBadge = 'Hi-Fi';
      _selectedGenre = 'All-Rounder';
      _selectedCountry = 'US';
      _hasUnsavedChanges = true;
    });
  }

  void _showCountryPicker() {
    CountryRegionSelectionSheet.show(
      context,
      currentCountryCode: _selectedCountry,
      onCountrySelected: (countryCode) {
        setState(() {
          _selectedCountry = countryCode;
          _hasUnsavedChanges = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = (_isIndexValid(_selectedColorIndex))
        ? AppColors.accentPalette[_selectedColorIndex]
        : AppColors.accentGreen;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          // 2. AVATAR & PROFILE PICTURE
          _buildSectionHeader('Profile Picture & Avatar'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Storage Photo Selector Card
                _buildCustomPhotoSection(activeAccent),
                const SizedBox(height: 18),
                const Divider(color: AppColors.glassBorder, height: 1),
                const SizedBox(height: 14),
                Text(
                  'Or Choose an Icon Preset',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
          Builder(
            builder: (context) {
              final countryInfo = CountryRegionSelectionSheet.allCountries.firstWhere(
                (c) => c.code.toUpperCase() == _selectedCountry.toUpperCase(),
                orElse: () => CountryRegionSelectionSheet.allCountries.first,
              );

              return _buildCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        countryInfo.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    countryInfo.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    countryInfo.chartDescription,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: activeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: activeAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          countryInfo.code,
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
              );
            },
          ),
          const SizedBox(height: 28),

          // 8. SAVE & RESET BUTTONS (Equal Size)
          Row(
            children: [
              Expanded(
                flex: 1,
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
                flex: 1,
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
    final effectiveCustomPath = _customAvatarRemoved ? null : _customAvatarPath;

    return ExpressiveCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(26),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.75),
      child: Column(
        children: [
          // Live Avatar with glowing multi-layer gradient or local photo
          Center(
            child: UserAvatar(
              size: 92,
              customAvatarPath: effectiveCustomPath,
              avatarIcon: _selectedAvatarIcon,
              avatarColorIndex: _selectedColorIndex,
              accentColor: accent,
              showGlow: true,
              borderWidth: 2.5,
              badge: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Icon(
                  effectiveCustomPath != null
                      ? LucideIcons.camera
                      : LucideIcons.sparkles,
                  size: 14,
                  color: accent,
                ),
              ),
              onTap: () => _showImageSourcePicker(accent),
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

  Widget _buildCustomPhotoSection(Color accent) {
    final hasCustom = _customAvatarPath != null && !_customAvatarRemoved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCustom ? accent.withValues(alpha: 0.4) : AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasCustom)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_customAvatarPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.darkSurfaceElevated,
                      child: const Icon(LucideIcons.image, size: 24),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(LucideIcons.imagePlus, color: accent, size: 24),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCustom ? 'Custom Photo Active' : 'Custom Profile Picture',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasCustom ? accent : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCustom
                          ? 'Using local photo from device storage'
                          : 'Upload an image from local storage or take a photo',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showImageSourcePicker(accent),
                  icon: Icon(
                    hasCustom ? LucideIcons.refreshCw : LucideIcons.upload,
                    size: 16,
                  ),
                  label: Text(hasCustom ? 'Change Photo' : 'Choose from Storage'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent.withValues(alpha: 0.18),
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: accent.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
              ),
              if (hasCustom) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _removeCustomAvatar,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPink,
                    side: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(Color accent) {
    final hasCustom = _customAvatarPath != null && !_customAvatarRemoved;

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
        final isSelected = !hasCustom && preset.id == _selectedAvatarIcon;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedAvatarIcon = preset.id;
              _customAvatarPath = null;
              _customAvatarRemoved = true;
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
