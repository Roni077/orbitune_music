import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Comprehensive Language Model
class AppLanguageInfo {
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
  final String completionBadge; // '100% Native', '100% Complete', 'Community'

  const AppLanguageInfo({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
    this.completionBadge = '100% Complete',
  });
}

/// Material 3 Expressive Selection Sheet & Dialog for App Interface Language
class LanguageSelectionSheet extends StatefulWidget {
  final String currentLanguageCode;
  final ValueChanged<String> onLanguageSelected;

  const LanguageSelectionSheet({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  /// Complete list of supported languages
  static const List<AppLanguageInfo> allLanguages = [
    AppLanguageInfo(
      code: 'en',
      nativeName: 'English (US)',
      englishName: 'English',
      flag: '🇺🇸',
      completionBadge: 'Native (Default)',
    ),
    AppLanguageInfo(
      code: 'es',
      nativeName: 'Español',
      englishName: 'Spanish',
      flag: '🇪🇸',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'fr',
      nativeName: 'Français',
      englishName: 'French',
      flag: '🇫🇷',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'de',
      nativeName: 'Deutsch',
      englishName: 'German',
      flag: '🇩🇪',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'ja',
      nativeName: '日本語',
      englishName: 'Japanese',
      flag: '🇯🇵',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'hi',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      flag: '🇮🇳',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'pt',
      nativeName: 'Português (Brasil)',
      englishName: 'Portuguese',
      flag: '🇧🇷',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'ko',
      nativeName: '한국어',
      englishName: 'Korean',
      flag: '🇰🇷',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'it',
      nativeName: 'Italiano',
      englishName: 'Italian',
      flag: '🇮🇹',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'zh',
      nativeName: '简体中文',
      englishName: 'Simplified Chinese',
      flag: '🇨🇳',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'ru',
      nativeName: 'Русский',
      englishName: 'Russian',
      flag: '🇷🇺',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
      flag: '🇸🇦',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'id',
      nativeName: 'Bahasa Indonesia',
      englishName: 'Indonesian',
      flag: '🇮🇩',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'tr',
      nativeName: 'Türkçe',
      englishName: 'Turkish',
      flag: '🇹🇷',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'vi',
      nativeName: 'Tiếng Việt',
      englishName: 'Vietnamese',
      flag: '🇻🇳',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'nl',
      nativeName: 'Nederlands',
      englishName: 'Dutch',
      flag: '🇳🇱',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'sv',
      nativeName: 'Svenska',
      englishName: 'Swedish',
      flag: '🇸🇪',
      completionBadge: '100% Complete',
    ),
    AppLanguageInfo(
      code: 'pl',
      nativeName: 'Polski',
      englishName: 'Polish',
      flag: '🇵🇱',
      completionBadge: '100% Complete',
    ),
  ];

  static AppLanguageInfo getInfo(String code) {
    return allLanguages.firstWhere(
      (l) => l.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AppLanguageInfo(
        code: code,
        nativeName: code,
        englishName: code,
        flag: '🌐',
      ),
    );
  }

  /// Shows the Language Selection Dialog
  static Future<String?> show(
    BuildContext context, {
    required String currentLanguageCode,
    required ValueChanged<String> onLanguageSelected,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LanguageSelectionSheet(
                currentLanguageCode: currentLanguageCode,
                onLanguageSelected: onLanguageSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the dialog version
  static Future<String?> showAsDialog(
    BuildContext context, {
    required String currentLanguageCode,
    required ValueChanged<String> onLanguageSelected,
  }) =>
      show(
        context,
        currentLanguageCode: currentLanguageCode,
        onLanguageSelected: onLanguageSelected,
      );

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

/// Backward compatibility alias
typedef LanguageSelectionDialog = LanguageSelectionSheet;

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguageInfo> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return LanguageSelectionSheet.allLanguages;
    }
    return LanguageSelectionSheet.allLanguages.where((lang) {
      return lang.nativeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.englishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLanguages;

    return Container(
      constraints: const BoxConstraints(maxHeight: 660),
      decoration: const BoxDecoration(
        color: AppColors.darkSurfaceElevated,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentIndigo.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.languages,
                      color: AppColors.accentIndigo,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Interface Language',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose your primary display & navigation language',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search language or locale code...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.glassBorder, height: 1),

            // Languages List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 40,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No languages matching "$_searchQuery"',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final lang = filtered[index];
                        final isSelected = lang.code.toLowerCase() ==
                            widget.currentLanguageCode.toLowerCase();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ExpressiveCard(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onLanguageSelected(lang.code);
                              Navigator.of(context).pop(lang.code);
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? AppColors.accentIndigo.withValues(alpha: 0.12)
                                : AppColors.darkSurfaceVariant
                                    .withValues(alpha: 0.35),
                            borderColor: isSelected
                                ? AppColors.accentIndigo
                                : AppColors.glassBorder.withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                // Flag / Language Avatar
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentIndigo
                                            .withValues(alpha: 0.2)
                                        : AppColors.darkSurfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentIndigo
                                          : AppColors.glassBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      lang.flag,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Native Name and English Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              lang.nativeName,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppColors.accentIndigo
                                                    : AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Locale Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentIndigo
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              lang.code.toUpperCase(),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.accentIndigo,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            lang.englishName,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            lang.completionBadge,
                                            style: AppTypography.caption
                                                .copyWith(
                                              color: isSelected
                                                  ? AppColors.accentIndigo
                                                  : AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Checkmark / Radio
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.accentIndigo
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentIndigo
                                          : AppColors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          LucideIcons.check,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
