import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/media_platform.dart';
import 'package:petal/widgets/media/media_platform_badge.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Uses the same network/provider resolution as the shared media cards.
class OverviewPlatformBadge extends StatefulWidget {
  final int tmdbId;
  final MediaType type;
  const OverviewPlatformBadge({super.key, required this.tmdbId, required this.type});

  @override
  State<OverviewPlatformBadge> createState() => _OverviewPlatformBadgeState();
}

class _OverviewPlatformBadgeState extends State<OverviewPlatformBadge> {
  String? _region;
  Future<MediaPlatform?>? _platform;

  void _load() {
    _platform = TMDB.mediaPlatform(widget.tmdbId, widget.type, region: _region)
        .catchError((Object _) => null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final region = Localizations.maybeLocaleOf(context)?.countryCode ??
        View.of(context).platformDispatcher.locale.countryCode;
    if (_platform == null || _region != region) {
      _region = region;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant OverviewPlatformBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId || oldWidget.type != widget.type) _load();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    top: MediaQuery.paddingOf(context).top + 12,
    right: 16,
    child: FutureBuilder<MediaPlatform?>(
      future: _platform,
      builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done &&
          snapshot.data != null
          ? MediaPlatformBadge(platform: snapshot.data!, size: 48)
          : const SizedBox.shrink(),
    ),
  );
}
