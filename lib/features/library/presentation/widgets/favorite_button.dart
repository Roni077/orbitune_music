import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';

/// Animated Heart Favorite button with spring scale feedback
class FavoriteButton extends ConsumerStatefulWidget {
  final Track track;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsets padding;

  const FavoriteButton({
    super.key,
    required this.track,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutBack,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(bool isFav) async {
    HapticFeedback.lightImpact();
    _animController.forward(from: 0.0);
    await ref.read(favoritesProvider.notifier).toggleFavorite(widget.track);
  }

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(isFavoriteProvider(widget.track.id));
    final activeColor = widget.activeColor ?? AppColors.accentPink;
    final inactiveColor = widget.inactiveColor ?? AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(isFav),
      child: Padding(
        padding: widget.padding,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            isFav ? LucideIcons.heart : LucideIcons.heart,
            color: isFav ? activeColor : inactiveColor,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
