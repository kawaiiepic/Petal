import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/widgets/profile/profile_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

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
    const avatarSize = 32.0;

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
                  context: buttonContext,
                  builder: (context) {
                    return DropdownMenu(
                      children: [
                        MenuLabel(child: Text('My Account')),
                        MenuDivider(),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BackendApi.authState.selectedProfile?.avatar != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${Api.ProfileUrl}/${BackendApi.authState.selectedProfile?.avatar}',
                          imageBuilder: (context, imageProvider) => Avatar(
                            initials: '',
                            provider: imageProvider,
                            size: avatarSize,
                            badge: const AvatarBadge(
                              size: 8,
                              color: Colors.green,
                            ),
                          ),
                        )
                      : const Icon(RadixIcons.avatar, size: avatarSize),
                  Text(
                    BackendApi.authState.selectedProfile?.name ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
