import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Comprehensive Country and Music Region definition
class CountryRegionInfo {
  final String code;
  final String name;
  final String flag;
  final String chartDescription;
  final String category; // 'Global', 'Popular', 'Americas', 'Europe', 'Asia & Pacific', 'Africa & Middle East'

  const CountryRegionInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.chartDescription,
    required this.category,
  });
}

/// Material 3 Expressive Selection Sheet & Dialog for Music Country / Region
class CountryRegionSelectionSheet extends StatefulWidget {
  final String currentCountryCode;
  final ValueChanged<String> onCountrySelected;

  const CountryRegionSelectionSheet({
    super.key,
    required this.currentCountryCode,
    required this.onCountrySelected,
  });

  /// Comprehensive catalog of supported regional music charts & discovery catalogs
  static const List<CountryRegionInfo> allCountries = [
    CountryRegionInfo(
      code: 'GLOBAL',
      name: 'Global Worldwide',
      flag: '🌐',
      chartDescription: 'Worldwide Top 50 & Global Viral Hits',
      category: 'Global',
    ),
    CountryRegionInfo(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      chartDescription: 'Billboard Hot 100, US Top 50 & Hip-Hop Trends',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'IN',
      name: 'India',
      flag: '🇮🇳',
      chartDescription: 'Bollywood Top 50, Punjabi Hits & Desi Hip Hop',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      chartDescription: 'Official UK Top 40, Drill & Indie Charts',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'CA',
      name: 'Canada',
      flag: '🇨🇦',
      chartDescription: 'Canadian Hot 100 & Pop Hits',
      category: 'Americas',
    ),
    CountryRegionInfo(
      code: 'AU',
      name: 'Australia',
      flag: '🇦🇺',
      chartDescription: 'ARIA Top 50 & Triple J Hottest Tracks',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'DE',
      name: 'Germany',
      flag: '🇩🇪',
      chartDescription: 'Offizielle Deutsche Charts & Techno/EDM Hits',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'FR',
      name: 'France',
      flag: '🇫🇷',
      chartDescription: 'Top Singles France & French Rap Trends',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'JP',
      name: 'Japan',
      flag: '🇯🇵',
      chartDescription: 'Oricon Charts, J-Pop & Anime Soundtracks',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'KR',
      name: 'South Korea',
      flag: '🇰🇷',
      chartDescription: 'Melon Top 100, K-Pop Global & K-Indie',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'BR',
      name: 'Brazil',
      flag: '🇧🇷',
      chartDescription: 'Funk Carioca, Sertanejo Pop & Brazil Top 50',
      category: 'Popular',
    ),
    CountryRegionInfo(
      code: 'MX',
      name: 'Mexico',
      flag: '🇲🇽',
      chartDescription: 'Regional Mexicano, Corridos & Latin Pop',
      category: 'Americas',
    ),
    CountryRegionInfo(
      code: 'ES',
      name: 'Spain',
      flag: '🇪🇸',
      chartDescription: 'Promusicae Top 50 & Reggaeton Hits',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'IT',
      name: 'Italy',
      flag: '🇮🇹',
      chartDescription: 'FIMI Top 50 & Sanremo Hits',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'NL',
      name: 'Netherlands',
      flag: '🇳🇱',
      chartDescription: 'Dutch Top 40 & Dance/EDM Anthems',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'SE',
      name: 'Sweden',
      flag: '🇸🇪',
      chartDescription: 'Sverigetopplistan & Nordic Pop Trends',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'NO',
      name: 'Norway',
      flag: '🇳🇴',
      chartDescription: 'VG-Lista Top 40 & Scandinavian Beats',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'ID',
      name: 'Indonesia',
      flag: '🇮🇩',
      chartDescription: 'Indonesian Pop, Dangdut & Viral TikTok Hits',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'PH',
      name: 'Philippines',
      flag: '🇵🇭',
      chartDescription: 'OPM Hits, P-Pop & Acoustic Ballads',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'VN',
      name: 'Vietnam',
      flag: '🇻🇳',
      chartDescription: 'V-Pop Top Hits & Ballads',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'TH',
      name: 'Thailand',
      flag: '🇹🇭',
      chartDescription: 'T-Pop Trends & Thai Indie Rock',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'TR',
      name: 'Turkey',
      flag: '🇹🇷',
      chartDescription: 'Turkish Pop, Arabesque & Rap Trends',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'SA',
      name: 'Saudi Arabia',
      flag: '🇸🇦',
      chartDescription: 'Khaliji Top Tracks & Arabic Trends',
      category: 'Africa & Middle East',
    ),
    CountryRegionInfo(
      code: 'AE',
      name: 'United Arab Emirates',
      flag: '🇦🇪',
      chartDescription: 'Middle East Chart & International Beats',
      category: 'Africa & Middle East',
    ),
    CountryRegionInfo(
      code: 'ZA',
      name: 'South Africa',
      flag: '🇿🇦',
      chartDescription: 'Amapiano Grooves, Afro-House & South African Pop',
      category: 'Africa & Middle East',
    ),
    CountryRegionInfo(
      code: 'NG',
      name: 'Nigeria',
      flag: '🇳🇬',
      chartDescription: 'Afrobeats Worldwide & Lagos Street Vibes',
      category: 'Africa & Middle East',
    ),
    CountryRegionInfo(
      code: 'AR',
      name: 'Argentina',
      flag: '🇦🇷',
      chartDescription: 'Argentine Trap, Cumbia & Rock Nacional',
      category: 'Americas',
    ),
    CountryRegionInfo(
      code: 'CO',
      name: 'Colombia',
      flag: '🇨🇴',
      chartDescription: 'Urbano Latino, Vallenato & Salsa',
      category: 'Americas',
    ),
    CountryRegionInfo(
      code: 'CL',
      name: 'Chile',
      flag: '🇨🇱',
      chartDescription: 'Urban Chileno & Indie Hits',
      category: 'Americas',
    ),
    CountryRegionInfo(
      code: 'NZ',
      name: 'New Zealand',
      flag: '🇳🇿',
      chartDescription: 'Official NZ Top 40 & Kiwi Sounds',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'CH',
      name: 'Switzerland',
      flag: '🇨🇭',
      chartDescription: 'Swiss Hitparade Top 100',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'AT',
      name: 'Austria',
      flag: '🇦🇹',
      chartDescription: 'Ö3 Austria Top 40',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'PL',
      name: 'Poland',
      flag: '🇵🇱',
      chartDescription: 'Polish Hip-Hop & OLiS Top Hits',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'PT',
      name: 'Portugal',
      flag: '🇵🇹',
      chartDescription: 'Top Nacional & Fado Moderno',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'IE',
      name: 'Ireland',
      flag: '🇮🇪',
      chartDescription: 'Irish Singles Chart & Folk/Rock',
      category: 'Europe',
    ),
    CountryRegionInfo(
      code: 'SG',
      name: 'Singapore',
      flag: '🇸🇬',
      chartDescription: 'Regional Asian & Western Top 50',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'MY',
      name: 'Malaysia',
      flag: '🇲🇾',
      chartDescription: 'Malay Hits, Mandopop & K-Pop',
      category: 'Asia & Pacific',
    ),
    CountryRegionInfo(
      code: 'EG',
      name: 'Egypt',
      flag: '🇪🇬',
      chartDescription: 'Mahraganat, Shaabi & Arabic Pop',
      category: 'Africa & Middle East',
    ),
  ];

  static CountryRegionInfo getInfo(String code) {
    return allCountries.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => CountryRegionInfo(
        code: code,
        name: code,
        flag: '🌐',
        chartDescription: 'Regional Charts & Top Tracks',
        category: 'Global',
      ),
    );
  }

  /// Shows the Material 3 Expressive Region Selection Modal Dialog
  static Future<String?> show(
    BuildContext context, {
    required String currentCountryCode,
    required ValueChanged<String> onCountrySelected,
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
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
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
              child: CountryRegionSelectionSheet(
                currentCountryCode: currentCountryCode,
                onCountrySelected: onCountrySelected,
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
    required String currentCountryCode,
    required ValueChanged<String> onCountrySelected,
  }) =>
      show(
        context,
        currentCountryCode: currentCountryCode,
        onCountrySelected: onCountrySelected,
      );

  @override
  State<CountryRegionSelectionSheet> createState() =>
      _CountryRegionSelectionSheetState();
}

/// Backward compatibility alias
typedef CountryRegionSelectionDialog = CountryRegionSelectionSheet;

class _CountryRegionSelectionSheetState
    extends State<CountryRegionSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Popular',
    'Americas',
    'Europe',
    'Asia & Pacific',
    'Africa & Middle East',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryRegionInfo> get _filteredCountries {
    return CountryRegionSelectionSheet.allCountries.where((country) {
      final matchesSearch = _searchQuery.isEmpty ||
          country.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          country.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          country.chartDescription
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          country.category == _selectedCategory ||
          (_selectedCategory == 'Popular' && country.category == 'Popular') ||
          (_selectedCategory == 'Americas' && country.category == 'Americas') ||
          (_selectedCategory == 'Europe' && country.category == 'Europe') ||
          (_selectedCategory == 'Asia & Pacific' &&
              country.category == 'Asia & Pacific') ||
          (_selectedCategory == 'Africa & Middle East' &&
              country.category == 'Africa & Middle East');

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCountries;

    return Container(
      constraints: const BoxConstraints(maxHeight: 680),
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
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.globe,
                      color: AppColors.accentCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Music Country & Region',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sets top charts, trending songs & regional discovery',
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
                    hintText: 'Search country or region...',
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

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentCyan
                            : AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentCyan
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.glassBorder, height: 1),

            // Country List
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
                            'No countries found for "$_searchQuery"',
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
                        final country = filtered[index];
                        final isSelected = country.code.toUpperCase() ==
                            widget.currentCountryCode.toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ExpressiveCard(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onCountrySelected(country.code);
                              Navigator.of(context).pop(country.code);
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? AppColors.accentCyan.withValues(alpha: 0.12)
                                : AppColors.darkSurfaceVariant
                                    .withValues(alpha: 0.35),
                            borderColor: isSelected
                                ? AppColors.accentCyan
                                : AppColors.glassBorder.withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                // Flag Avatar
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentCyan
                                            .withValues(alpha: 0.2)
                                        : AppColors.darkSurfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentCyan
                                          : AppColors.glassBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title and Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              country.name,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppColors.accentCyan
                                                    : AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Country Code Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentCyan
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              country.code,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.accentCyan,
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
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                        ? AppColors.accentCyan
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentCyan
                                          : AppColors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          LucideIcons.check,
                                          size: 13,
                                          color: Colors.black,
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
