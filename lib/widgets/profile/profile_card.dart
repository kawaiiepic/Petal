import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/watch_session.dart';
import 'package:petal/widgets/avatar_crop_dialog.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ProfileCard extends StatefulWidget {
  final String id;
  final String name;
  final String? avatar;
  final bool add;
  final VoidCallback? onSelect;
  final Future<void> Function(String username)? onCreate;

  const ProfileCard({
    required this.name,
    required this.avatar,
    this.add = false,
    this.onSelect,
    this.onCreate,
    required this.id,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool hovering = false;
  bool creating = false;

  Future<void> pickAvatar() async {
    final file = await FilePicker.pickFile(type: FileType.image);

    if (file != null) {
      final boop = File(file.path!);
      if (mounted) {
        showOverlay(
          context,
          DialogConfiguration(),
          builder: (_) => AvatarCropDialog(image: boop),
        );
      }
    }
  }

  void _openCreateDialog() {
    showOverlay(
      context,
      DialogConfiguration(),
      builder: (dialogContext) {
        final TextEditingController usernameController =
            TextEditingController();

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Create New Profile'),
              content: SizedBox(
                width: 320,
                child: TextField(
                  controller: usernameController,
                  autofocus: true,
                  placeholder: Text('Enter a username'),
                ),
              ),
              actions: [
                SecondaryButton(
                  onPressed: creating ? null : () => dialogContext.pop(),
                  child: Text('Cancel'),
                ),
                PrimaryButton(
                  onPressed: creating
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          if (username.isEmpty || widget.onCreate == null)
                            return;

                          setDialogState(() => creating = true);
                          await widget.onCreate!(username);
                          if (mounted) setDialogState(() => creating = false);
                        },
                  child: creating ? Text('Creating...') : Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = BackendApi.authState.selectedProfile?.id == widget.id;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: Button(
        style: ButtonVariance.text,
        onPressed: () {
          if (widget.add) {
            _openCreateDialog();
          } else if (isSelected) {
            pickAvatar();
          } else {
            widget.onSelect?.call();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: BackendCache.sessions,
          builder: (context, value, child) {
            WatchSession? selectedSession = value.firstWhereOrNull(
              (s) => s.profileId == widget.id,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!widget.add)
                      widget.avatar != null
                          ? CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: '${Api.ProfileUrl}/${widget.avatar}',
                              imageBuilder: (context, imageProvider) => Avatar(
                                initials: '',
                                provider: imageProvider,
                                size: 70,
                                badge: selectedSession != null
                                    ? const AvatarBadge()
                                    : null,
                              ),
                            )
                          : const Icon(RadixIcons.avatar, size: 70),
                    if (widget.add)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    if (hovering && isSelected)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(220),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.squarePen,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.name),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      const Icon(LucideIcons.check, size: 16),
                    ],
                  ],
                ),
                if (selectedSession != null) Text('${selectedSession.title}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
