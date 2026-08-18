import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Dialog to save custom frequency gain configurations as a named EQ preset
class SavePresetDialog extends StatefulWidget {
  final ValueChanged<String> onSave;
  final String? initialName;

  const SavePresetDialog({
    super.key,
    required this.onSave,
    this.initialName,
  });

  /// Shows the save preset dialog
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSave,
    String? initialName,
  }) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      builder: (_) => SavePresetDialog(
        onSave: onSave,
        initialName: initialName,
      ),
    );
  }

  @override
  State<SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<SavePresetDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? 'My Preset');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Preset name cannot be empty');
      return;
    }
    if (text.toLowerCase() == 'flat' || text.toLowerCase() == 'custom') {
      setState(() => _errorText = 'Please choose a distinct custom name');
      return;
    }

    HapticFeedback.selectionClick();
    widget.onSave(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.roundedLarge,
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: Row(
        children: [
          const Icon(LucideIcons.save, color: AppColors.accentGreen, size: 22),
          const SizedBox(width: 10),
          Text(
            'Save EQ Preset',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save your current frequency band gains and DSP settings as a reusable preset.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Preset Name',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              errorText: _errorText,
              enabledBorder: OutlineInputBorder(
                borderRadius: AppConstants.roundedMedium,
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppConstants.roundedMedium,
                borderSide: const BorderSide(color: AppColors.accentGreen),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.roundedSmall,
            ),
          ),
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
