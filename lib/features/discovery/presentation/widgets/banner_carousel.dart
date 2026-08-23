import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';

/// Hero trending banner carousel with parallax effect, glassmorphic badges & 1-tap play
class BannerCarousel extends StatefulWidget {
  final List<TrendingItem> items;
  final ValueChanged<TrendingItem>? onItemTap;
  final ValueChanged<TrendingItem>? onPlayTap;

  const BannerCarousel({
    super.key,
    required this.items,
    this.onItemTap,
    this.onPlayTap,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final page = _pageController.page ?? _currentPage.toDouble();
                    final diff = (page - index).abs();
                    scale = (1.0 - (diff * 0.08)).clamp(0.88, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _buildBannerCard(item),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Smooth Page Indicator Dots
        if (widget.items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: isActive ? 22.0 : 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentGreen : AppColors.divider,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildBannerCard(TrendingItem item) {
    final imageUrl = item.bannerUrl ?? item.artworkUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ClipRRect(
        borderRadius: AppConstants.roundedLarge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Shimmer
            ImageShimmer(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppConstants.roundedLarge,
            ),

            // Dark Multi-Stop Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content Overlay
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (widget.onItemTap != null) {
                    widget.onItemTap!(item);
                  } else if (widget.onPlayTap != null) {
                    widget.onPlayTap!(item);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          'FEATURED',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title & Subtitle Row with Play Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Primary Play Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onPlayTap?.call(item);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x6622C55E),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.play,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
