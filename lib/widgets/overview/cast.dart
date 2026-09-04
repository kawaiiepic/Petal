import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CastCard extends StatelessWidget {
  final CastMember? member;

  const CastCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => member != null ? context.push('/person/${member!.id}') : null,
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
                      errorBuilder: (_, _, _) => _CastFallbackAvatar(),
                    )
                  : _CastFallbackAvatar(),
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
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CastFallbackAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(BootstrapIcons.personFill, color: Colors.white.withOpacity(0.38)),
    );
  }
}
