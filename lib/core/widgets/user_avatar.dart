import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';

/// Material 3 Expressive User Avatar widget supporting custom local storage images
/// and icon presets with dynamic glow and accent gradients.
class UserAvatar extends StatelessWidget {
  final double size;
  final String? customAvatarPath;
  final String? avatarIcon;
  final int avatarColorIndex;
  final Color? accentColor;
  final bool showGlow;
  final double borderWidth;
  final Widget? badge;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.size = 48.0,
    this.customAvatarPath,
    this.avatarIcon,
    this.avatarColorIndex = 0,
    this.accentColor,
    this.showGlow = true,
    this.borderWidth = 2.0,
    this.badge,
    this.onTap,
  });

  Color _resolveAccent() {
    if (accentColor != null) return accentColor!;
    if (avatarColorIndex >= 0 &&
        avatarColorIndex < AppColors.accentPalette.length) {
      return AppColors.accentPalette[avatarColorIndex];
    }
    return AppColors.accentGreen;
  }

  static IconData getIconData(String? iconName) {
    switch (iconName) {
      case 'headphones':
        return LucideIcons.headphones;
      case 'music':
        return LucideIcons.music;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'disc':
        return LucideIcons.disc;
      case 'flame':
        return LucideIcons.flame;
      case 'heart':
        return LucideIcons.heart;
      case 'zap':
        return LucideIcons.zap;
      case 'rocket':
        return LucideIcons.rocket;
      case 'star':
        return LucideIcons.star;
      case 'radio':
        return LucideIcons.radio;
      case 'mic':
        return LucideIcons.mic;
      case 'user':
      default:
        return LucideIcons.user;
    }
  }

  bool _hasValidLocalImage() {
    if (customAvatarPath == null || customAvatarPath!.trim().isEmpty) {
      return false;
    }
    try {
      final file = File(customAvatarPath!);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resolveAccent();
    final hasImage = _hasValidLocalImage();

    Widget avatarContent;

    if (hasImage) {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: borderWidth > 0
              ? Border.all(
                  color: accent,
                  width: borderWidth,
                )
              : null,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: size * 0.35,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.file(
            File(customAvatarPath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0)).toInt(),
            cacheHeight: (size * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0)).toInt(),
            errorBuilder: (_, __, ___) => _buildPresetIcon(accent),
          ),
        ),
      );
    } else {
      avatarContent = Container(
        width: size,
        height: size,
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
          border: borderWidth > 0
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: borderWidth,
                )
              : null,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            getIconData(avatarIcon),
            size: size * 0.46,
            color: Colors.black,
          ),
        ),
      );
    }

    Widget result = avatarContent;

    if (badge != null) {
      result = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarContent,
          Positioned(
            bottom: 0,
            right: 0,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    return result;
  }

  Widget _buildPresetIcon(Color accent) {
    return Container(
      width: size,
      height: size,
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
      ),
      child: Center(
        child: Icon(
          getIconData(avatarIcon),
          size: size * 0.46,
          color: Colors.black,
        ),
      ),
    );
  }
}
