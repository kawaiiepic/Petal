import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/social/social_profile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ProfileResultRow extends StatelessWidget {
  final SocialProfile profile;

  const ProfileResultRow({required this.profile});

  String? get _avatarUrl {
    final avatar = profile.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http')) return avatar;
    return '${Api.ProfileUrl}/$avatar';
  }

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';
    final url = _avatarUrl;

    final avatar = url == null
        ? Avatar(initials: initials, size: 36)
        : CachedNetworkImage(
            imageUrl: url,
            imageBuilder: (context, provider) =>
                Avatar(initials: initials, provider: provider, size: 36),
            placeholder: (context, _) => Avatar(initials: initials, size: 36),
            errorWidget: (context, _, _) =>
                Avatar(initials: initials, size: 36),
          );

    return Button.ghost(
      alignment: Alignment.centerLeft,
      onPressed: () => context.push('/profile/${profile.id}'),
      leading: avatar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(profile.name),
      ),
    );
  }
}
