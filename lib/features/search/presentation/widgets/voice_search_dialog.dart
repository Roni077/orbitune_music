import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Interactive Voice Search Modal with animated soundwave pulsation
class VoiceSearchModal extends StatefulWidget {
  final ValueChanged<String> onVoiceRecognized;

  const VoiceSearchModal({
    super.key,
    required this.onVoiceRecognized,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onVoiceRecognized,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VoiceSearchModal(
        onVoiceRecognized: onVoiceRecognized,
      ),
    );
  }

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
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
    return Container(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Listening...',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say the name of a song, artist, album, or playlist',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // Pulsing Microphone Core
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Ring
                  Container(
                    width: 120 * _pulseAnimation.value,
                    height: 120 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGreen.withValues(
                        alpha: 0.15 * (1.2 - _pulseAnimation.value),
                      ),
                    ),
                  ),
                  // Middle Ring
                  Container(
                    width: 96 * _pulseAnimation.value,
                    height: 96 * _pulseAnimation.value,
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
                      width: 76,
                      height: 76,
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
                        size: 34,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 36),

          // Quick Voice Prompt Suggestions
          Text(
            'Or try saying:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickVoicePrompts.map((prompt) {
              return ActionChip(
                backgroundColor: AppColors.darkSurfaceVariant,
                label: Text(
                  prompt,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => _submitVoiceText(prompt),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Fallback text input inside modal
          TextField(
            controller: _textController,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Or type speech manually...',
              hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.darkSurfaceVariant,
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
    );
  }
}
