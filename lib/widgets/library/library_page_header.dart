import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/navigation/user_profile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Shared title treatment for the Collection, History, and Downloads screens.
class LibraryPageHeader extends StatelessWidget {
  const LibraryPageHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.action,
    this.showAccount = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 8 : 24,
        compact ? 16 : 24,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (!compact) Icon(icon, size: 24, color: colors.mutedForeground),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 30 : 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              if (action != null) action!,
              if (compact && showAccount) const UserProfile(avatarOnly: true),
            ],
          ),
          Text(description, style: TextStyle(color: colors.mutedForeground)),
        ],
      ),
    );
  }
}
