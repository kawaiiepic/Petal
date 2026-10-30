import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/cast_member.dart';
import 'package:petal/widgets/overview/cast_fallback_avatar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CastCard extends StatelessWidget {
  final CastMember? member;
  final IconData fallbackIcon;

  const CastCard({
    super.key,
    required this.member,
    this.fallbackIcon = BootstrapIcons.personFill,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          member != null ? context.push('/person/${member!.id}') : null,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            ClipOval(
              child: member != null && member!.profilePath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w185${member!.profilePath}',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          CastFallbackAvatar(icon: fallbackIcon),
                    )
                  : CastFallbackAvatar(icon: fallbackIcon),
            ),
            const SizedBox(height: 8),
            Text(
              member?.name ?? 'Random Name',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (member?.character != null)
              Text(
                member!.character!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
