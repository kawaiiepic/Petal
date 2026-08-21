import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/main.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/widgets/crop.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _Profile();
}

class _Profile extends State<UserProfile> {
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = BackendApi.profiles();
    BackendApi.authState.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  void _refreshProfiles() {
    setState(() {
      _profilesFuture = BackendApi.profiles();
    });
  }

  void _selectProfile(Profile profile) {
    setState(() => BackendApi.authState.setProfile(profile));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Profile>>(
      future: _profilesFuture,
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? const <Profile>[];

        return Builder(
          builder: (buttonContext) {
            return Button(
              style: ButtonVariance.text,
              onPressed: () {
                showDropdown(
                  context: buttonContext, // scoped to the button, not the whole page
                  builder: (context) {
                    return DropdownMenu(
                      children: [
                        MenuLabel(child: Text('My Account')),
                        MenuDivider(),
                        MenuButton(
                          onPressed: (_) async {
                            PetalApp.refreshTriggerKey.currentState!.refresh();
                          },
                          child: const Text('Refresh'),
                        ),
                        MenuButton(
                          child: Text('Switch Profile'),
                          onPressed: (context) {
                            showOverlay(
                              buttonContext,
                              DialogConfiguration(
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Switch Profile', textAlign: TextAlign.center),
                                        const SizedBox(height: 20),

                                        Wrap(
                                          spacing: 20,
                                          runSpacing: 20,
                                          children: [
                                            for (final profile in profiles)
                                              _ProfileCard(
                                                id: profile.id,
                                                name: profile.name,
                                                avatar: profile.avatar,
                                                onSelect: () {
                                                  _selectProfile(profile);
                                                  dialogContext.pop();
                                                },
                                              ),
                                            _ProfileCard(
                                              id: "",
                                              name: "New Profile",
                                              avatar: "",
                                              add: true,
                                              onCreate: (username) async {
                                                try {
                                                  await BackendApi.addProfile(username);
                                                  _refreshProfiles();
                                                  if (dialogContext.mounted) dialogContext.pop();
                                                } catch (e) {
                                                  if (dialogContext.mounted) {
                                                    showToast(context: dialogContext, builder: (_, _) => Text('Could not create profile: $e'));
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        MenuButton(
                          onPressed: (_) async {
                            await BackendApi.signOut();

                            if (context.mounted) context.go('/login');
                          },
                          child: const Text('Log out'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Column(
                // spacing: 4,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 40, // 2 * radius
                      height: 40,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover, // fill can distort aspect ratio; cover crops instead
                        imageUrl: '${Api.ProfileUrl}/${BackendApi.authState.selectedProfile?.avatar}',
                        errorWidget: (context, url, error) => const Icon(Icons.account_circle_outlined, size: 35),
                      ),
                    ),
                  ),
                  Text(BackendApi.authState.selectedProfile?.name ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final String id;
  final String name;
  final String avatar;
  final bool add;
  final VoidCallback? onSelect;
  final Future<void> Function(String username)? onCreate;

  const _ProfileCard({required this.name, required this.avatar, this.add = false, this.onSelect, this.onCreate, required this.id});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool hovering = false;
  bool creating = false;

  Future<void> pickAvatar() async {
    final result = await FilePicker.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (mounted) {
        showOverlay(context, DialogConfiguration(builder: (_) => AvatarCropDialog(image: file)));
      }
    }
  }

  void _openCreateDialog() {
    showOverlay(
      context,
      DialogConfiguration(
        builder: (dialogContext) {
          final TextEditingController usernameController = TextEditingController();

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text('Create New Profile'),
                content: SizedBox(
                  width: 320,
                  child: TextField(controller: usernameController, autofocus: true, placeholder: Text('Enter a username')),
                ),
                actions: [
                  SecondaryButton(onPressed: creating ? null : () => dialogContext.pop(), child: Text('Cancel')),
                  PrimaryButton(
                    onPressed: creating
                        ? null
                        : () async {
                            final username = usernameController.text.trim();
                            if (username.isEmpty || widget.onCreate == null) return;

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
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (!widget.add)
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: SizedBox(
                        width: 70, // 2 * radius
                        height: 70,
                        child: CachedNetworkImage(
                          fit: BoxFit.cover, // fill can distort aspect ratio; cover crops instead
                          imageUrl: '${Api.ProfileUrl}/${widget.avatar}',
                          errorWidget: (context, url, error) => const Icon(Icons.account_circle_outlined, size: 70),
                        ),
                      ),
                    ),
                  ),

                if (widget.add)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.black.withAlpha(100), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),

                if (hovering && isSelected)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.black.withAlpha(220), shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 28),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.name),
                if (isSelected) ...[const SizedBox(width: 5), const Icon(Icons.check, size: 16)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
