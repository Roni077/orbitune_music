import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Material 3 Expressive search bar with dynamic clear & voice input triggers
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceTap;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Songs, artists, albums, or paste URL...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onVoiceTap,
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _hasText = false;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = widget.controller.text.isNotEmpty;

    widget.controller.addListener(_onControllerUpdate);
    _focusNode.addListener(_onFocusUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _focusNode.removeListener(_onFocusUpdate);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() {
        _hasText = has;
      });
    }
  }

  void _onFocusUpdate() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.fastAnimation,
      curve: Curves.easeOutCubic,
      height: 52,
      decoration: BoxDecoration(
        color: _isFocused
            ? AppColors.darkSurfaceVariant
            : AppColors.darkSurface.withValues(alpha: 0.8),
        borderRadius: AppConstants.roundedLarge,
        border: Border.all(
          color: _isFocused
              ? AppColors.accentGreen.withValues(alpha: 0.6)
              : AppColors.glassBorder,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          // Search Icon
          Icon(
            LucideIcons.search,
            size: 20,
            color: _isFocused ? AppColors.accentGreen : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          // Text Input Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              cursorColor: AppColors.accentGreen,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                HapticFeedback.lightImpact();
                widget.onSubmitted?.call(value);
              },
            ),
          ),

          // Action Buttons: Clear & Voice Search
          if (_hasText) ...[
            IconButton(
              icon: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.textMuted,
              ),
              splashRadius: 20,
              tooltip: 'Clear search',
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.controller.clear();
                widget.onClear?.call();
              },
            ),
          ],

          if (widget.onVoiceTap != null) ...[
            IconButton(
              icon: Icon(
                LucideIcons.mic,
                size: 20,
                color: _isFocused ? AppColors.accentGreen : AppColors.textSecondary,
              ),
              splashRadius: 20,
              tooltip: 'Voice Search',
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onVoiceTap?.call();
              },
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
