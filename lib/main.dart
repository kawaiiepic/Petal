import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/api/discord_presence.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/query_proxy.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.load();
  await QueryProxy.load();
  await UserLibrary.load();
  await DownloadManager.load();
  await OfflineProgressSync.instance.load();
  OfflineProgressSync.instance.start(
    online: () => BackendApi.profileCacheKey != null,
  );

  MediaKit.ensureInitialized();
  Discord.init();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(PetalApp());

  WindowManager.instance.getCurrent()!.titleBarStyle = TitleBarStyle.hidden;
}
