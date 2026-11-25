import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/widgets/profile/profile_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({
    super.key,
    this.horizontal = false,
    this.avatarOnly = false,
  });

  final bool horizontal;
  final bool avatarOnly;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = BackendApi.profiles();
    BackendApi.authState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    BackendApi.authState.removeListener(_onAuthStateChanged);
    super.dispose();
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
    final avatarSize = widget.avatarOnly
        ? 38.0
        : widget.horizontal
        ? 26.0
        : 32.0;
    final profile = BackendApi.authState.selectedProfile;
    final fallback = Icon(
      RadixIcons.avatar,
      size: avatarSize,
      color: widget.avatarOnly ? Colors.white : null,
    );
    final avatar = profile?.avatar != null
        ? CachedNetworkImage(
            imageUrl: '${Api.ProfileUrl}/${profile?.avatar}',
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
            imageBuilder: (context, imageProvider) => Avatar(
              initials: '',
              provider: imageProvider,
              size: avatarSize,
              badge: const AvatarBadge(size: 8, color: Colors.green),
            ),
          )
        : fallback;
    final name = Text(
      profile?.name ?? (widget.horizontal ? 'Account' : ''),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );

    return FutureBuilder<List<Profile>>(
      future: _profilesFuture,
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? const <Profile>[];

        return Builder(
          builder: (buttonContext) {
            return Button(
              alignment: widget.horizontal
                  ? Alignment.centerLeft
                  : Alignment.center,
              style: widget.horizontal
                  ? ButtonVariance.text.withPadding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    )
                  : ButtonVariance.text,
              onPressed: () {
                showDropdown(
                  context: buttonContext,
                  builder: (context) {
                    return DropdownMenu(
                      children: [
                        MenuLabel(child: Text('My Account')),
                        MenuDivider(),
                        MenuButton(
                          onPressed: (_) => buttonContext.push('/home-layout'),
                          child: const Text('Customize Home'),
                        ),
                        MenuButton(
                          onPressed: (_) async => PetalApp
                              .rootNavigatorKey
                              .currentContext
                              ?.push('/addons'),
                          child: const Text('Addons'),
                        ),
                        MenuButton(
                          onPressed: (_) async => PetalApp
                              .rootNavigatorKey
                              .currentContext
                              ?.push('/settings'),
                          child: const Text('Settings'),
                        ),
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
                              DialogConfiguration(),
                              builder: (dialogContext) {
                                return AlertDialog(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Switch Profile',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 20,
                                        children: [
                                          for (final profile in profiles)
                                            ProfileCard(
                                              id: profile.id,
                                              name: profile.name,
                                              avatar: profile.avatar,
                                              onSelect: () {
                                                _selectProfile(profile);
                                                dialogContext.pop();
                                              },
                                            ),
                                          ProfileCard(
                                            id: "",
                                            name: "New Profile",
                                            avatar: "",
                                            add: true,
                                            onCreate: (username) async {
                                              try {
                                                await BackendApi.addProfile(
                                                  username,
                                                );
                                                _refreshProfiles();
                                                if (dialogContext.mounted)
                                                  dialogContext.pop();
                                              } catch (e) {
                                                if (dialogContext.mounted) {
                                                  showToast(
                                                    context: dialogContext,
                                                    builder: (_, _) => Text(
                                                      'Could not create profile: $e',
                                                    ),
                                                  );
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
              child: widget.avatarOnly
                  ? Semantics(
                      label: 'Account',
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x66000000),
                        ),
                        child: SizedBox.square(
                          dimension: 44,
                          child: Center(child: avatar),
                        ),
                      ),
                    )
                  : widget.horizontal
                  ? Row(
                      spacing: 8,
                      children: [
                        avatar,
                        Expanded(child: name),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [avatar, name],
                    ),
            );
          },
        );
      },
    );
  }
}
