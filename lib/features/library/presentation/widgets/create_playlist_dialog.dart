import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';

/// Modal Bottom Sheet to create a new user playlist or rename an existing playlist
class CreatePlaylistDialog extends ConsumerStatefulWidget {
  final UserPlaylist? initialPlaylist;
  final List<Track> initialTracks;

  const CreatePlaylistDialog({
    super.key,
    this.initialPlaylist,
    this.initialTracks = const [],
  });

  static Future<UserPlaylist?> show(
    BuildContext context, {
    UserPlaylist? initialPlaylist,
    List<Track> initialTracks = const [],
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<UserPlaylist?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlaylistDialog(
        initialPlaylist: initialPlaylist,
        initialTracks: initialTracks,
      ),
    );
  }

  @override
  ConsumerState<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialPlaylist?.name ?? '');
    _descController =
        TextEditingController(text: widget.initialPlaylist?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    setState(() => _isLoading = true);

    try {
      if (widget.initialPlaylist != null) {
        // Update existing playlist
        final updated = widget.initialPlaylist!.copyWith(
          name: name,
          description: desc.isNotEmpty ? desc : null,
          updatedAt: DateTime.now(),
        );
        await ref.read(userPlaylistsProvider.notifier).renamePlaylist(widget.initialPlaylist!.id, name);
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        // Create new playlist
        final newPlaylist = await ref.read(userPlaylistsProvider.notifier).createPlaylist(
              name,
              description: desc.isNotEmpty ? desc : null,
              initialTracks: widget.initialTracks,
            );
        if (mounted) Navigator.of(context).pop(newPlaylist);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save playlist: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isEditing = widget.initialPlaylist != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        isEditing ? LucideIcons.pencil : LucideIcons.listPlus,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Playlist' : 'New Playlist',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Playlist Name',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    hintText: 'e.g. Midnight Vibes',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a playlist name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    hintText: 'Add an optional description',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),
                if (widget.initialTracks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.music, size: 14, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'Includes ${widget.initialTracks.length} tracks',
                        style: AppTypography.caption.copyWith(color: primary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleSave,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save' : 'Create',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
