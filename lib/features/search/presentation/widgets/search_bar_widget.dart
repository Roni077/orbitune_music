import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SearchBar(
      controller: widget.controller,
      focusNode: _focusNode,
      autoFocus: widget.autofocus,
      hintText: widget.hintText,
      hintStyle: WidgetStateProperty.all(
        AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      textStyle: WidgetStateProperty.all(
        AppTypography.bodyLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      elevation: WidgetStateProperty.all(_isFocused ? 2.0 : 0.0),
      backgroundColor: WidgetStateProperty.all(
        _isFocused
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainer,
      ),
      side: WidgetStateProperty.all(
        BorderSide(
          color: _isFocused
              ? colorScheme.primary.withValues(alpha: 0.7)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14.0),
      ),
      leading: Icon(
        LucideIcons.search,
        size: 20,
        color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      trailing: [
        if (_hasText)
          IconButton(
            icon: const Icon(
              LucideIcons.x,
              size: 18,
            ),
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Clear search',
            onPressed: () {
              HapticFeedback.selectionClick();
              widget.controller.clear();
              widget.onClear?.call();
            },
          ),
        if (widget.onVoiceTap != null)
          IconButton(
            icon: Icon(
              LucideIcons.mic,
              size: 20,
              color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Voice Search',
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onVoiceTap?.call();
            },
          ),
      ],
      onChanged: widget.onChanged,
      onSubmitted: (value) {
        HapticFeedback.lightImpact();
        widget.onSubmitted?.call(value);
      },
    );
  }
}
