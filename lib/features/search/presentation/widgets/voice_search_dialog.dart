import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Interactive Voice Search Modal Dialog with animated soundwave pulsation
class VoiceSearchDialog extends StatefulWidget {
  final ValueChanged<String> onVoiceRecognized;

  const VoiceSearchDialog({
    super.key,
    required this.onVoiceRecognized,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onVoiceRecognized,
  }) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VoiceSearchDialog(
        onVoiceRecognized: onVoiceRecognized,
      ),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textController = TextEditingController();

  final List<String> _quickVoicePrompts = [
    'Play Arijit Singh',
    'Trending Hindi Songs',
    'Lofi Chill Beats',
    'Top Pop 2026',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submitVoiceText(String query) {
    if (query.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onVoiceRecognized(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Close button & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listening...',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Say the name of a song, artist, album, or playlist',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Pulsing Microphone Core
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glow Ring
                      Container(
                        width: 110 * _pulseAnimation.value,
                        height: 110 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen.withValues(
                            alpha: 0.15 * (1.2 - _pulseAnimation.value),
                          ),
                        ),
                      ),
                      // Middle Ring
                      Container(
                        width: 90 * _pulseAnimation.value,
                        height: 90 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      // Central Mic Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentGreen,
                                AppColors.accentCyan,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6600E5FF),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.mic,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick Voice Prompt Suggestions
              Text(
                'Try saying:',
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quickVoicePrompts.map((prompt) {
                  return ActionChip(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    label: Text(
                      prompt,
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => _submitVoiceText(prompt),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Fallback text input inside dialog
              TextField(
                controller: _textController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Or type search query...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: AppConstants.roundedMedium,
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.arrowRight, color: AppColors.accentGreen),
                    onPressed: () => _submitVoiceText(_textController.text),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _submitVoiceText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef VoiceSearchModal = VoiceSearchDialog;
