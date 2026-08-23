import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';

/// Translucent blurred Glassmorphic App Bar with action buttons
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBlur;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBlur = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget appBar = AppBar(
      title: Text(title, style: AppTypography.brandTitle.copyWith(fontSize: 22)),
      centerTitle: false,
      backgroundColor: showBlur ? AppColors.darkBackground.withValues(alpha: 0.7) : Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
    );

    if (!showBlur) return appBar;

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppConstants.glassBlurSigma,
            sigmaY: AppConstants.glassBlurSigma,
          ),
          child: appBar,
        ),
      ),
    );
  }
}
