import 'package:go_router/go_router.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PublicProfilePage extends StatefulWidget {
  final String profileId;

  const PublicProfilePage({super.key, required this.profileId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<SocialProfile?> _profile;
  late Future<List<WatchHistoryItem>> _history;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _profile = SocialApi.profile(widget.profileId);
    _history = _loadHistory();
  }

  Future<List<WatchHistoryItem>> _loadHistory() async {
    final response = await BackendApi.dio.get('${BackendApi.authState.selectedProfile == null ? '' : ''}${ /* keep dio via ServerUrl */ ''}');
    try {
      final url = (await _historyUrl());
      final res = await BackendApi.dio.get(url);
      final rows = res.data['result'] as List? ?? const [];
      return rows.map((e) => WatchHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> _historyUrl() async {
    return '${(await Future.value(''))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: const Text('Profile')),
      ],
      child: FutureBuilder(
        future: Future.wait([_profile, _history]),
        builder: (context, snapshot) {
          return const Center(child: Text('Loading profile…'));
        },
      ),
    );
  }
}
