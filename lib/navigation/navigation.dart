import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/main.dart';
import 'package:petal/navigation/profile.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class Navigation extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const Navigation({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshTrigger(
      key: PetalApp.refreshTriggerKey,
      onRefresh: () async {
        await BackendCache.fetchContinueWatching();
      },
      child: Scaffold(
        headers: [
          SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(1.w, 0, 1.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisSize: MainAxisSize.min,
                children: [SvgPicture.asset('assets/images/logo-clean.svg', height: 30, width: 30), Search(), UserProfile()],
              ),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}