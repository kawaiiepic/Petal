import 'package:petal/theme/app_typography.dart';
import 'package:petal/widgets/addons/addon_logo.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AddonHeader extends StatelessWidget {
  final String name;
  final String desc;
  final String? logo;
  final List<Widget> actions;

  const AddonHeader({
    required this.name,
    required this.desc,
    this.logo,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AddonLogo(logo: logo),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Loading...' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (desc.isNotEmpty)
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.smallSize,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
    );
  }
}
