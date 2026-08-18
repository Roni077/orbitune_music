import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';

/// Dialog to create a new user playlist or rename an existing playlist
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
    return showDialog<UserPlaylist?>(
      context: context,
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
    final isEditing = widget.initialPlaylist != null;

    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditing ? LucideIcons.pencil : LucideIcons.listPlus,
              color: AppColors.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Playlist' : 'New Playlist',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'e.g. Midnight Vibes',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.darkSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
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
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Add an optional description',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.darkSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                  ),
                ),
              ),
              if (widget.initialTracks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.music, size: 14, color: AppColors.accentCyan),
                    const SizedBox(width: 6),
                    Text(
                      'Includes ${widget.initialTracks.length} tracks',
                      style: AppTypography.caption.copyWith(color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
      ],
    );
  }
}
