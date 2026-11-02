import 'package:petal/api/playback_media_session.dart';
import 'package:petal/models/playback_item.dart';
import 'package:petal/pages/player/playback_scope.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/discord_presence.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/external_player.dart';
import 'package:petal/api/playback_source.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:petal/pages/player/player_orientation.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamPlayer extends StatefulWidget {
  final int mediaId;
  final Episode? episode;
  final StreamItem? stream;
  final double? progress;
  const StreamPlayer({
    super.key,
    required this.mediaId,
    required this.episode,
    this.stream,
    this.progress,
  });

  @override
  State<StatefulWidget> createState() => StreamPlayerState();
}

class StreamPlayerState extends State<StreamPlayer> {
  late PlaybackItem _item;
  bool _switching = true;
  MediaType mediaType = MediaType.movie;
  late final player = Player(configuration: PlayerConfiguration());
  late final VideoController controller;
  late final PlaybackMediaSession _mediaSession = PlaybackMediaSession(player);
  StreamItem? selectedStream;
  bool get isOffline => _item.isOffline;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? _profileKey;
  bool _resumeApplied = false;
  double? _lastWrittenProgress;
  bool zoomVideo = false;
  bool _finishedThisSession = false;

  Timer? _saveProgress;
  StreamSubscription<(bool, Duration)>? _discordSub;

  @override
  void initState() {
    super.initState();
    _item = PlaybackItem(
      mediaId: widget.mediaId,
      episode: widget.episode,
      stream: widget.stream,
      progress: widget.progress,
    );

    if (_item.episode != null) mediaType = MediaType.show;

    PlayerOrientation.lockLandscape();

    if (!isOffline) _profileKey = BackendApi.profileCacheKey;
    saveProgressTask();

    controller = VideoController(
      player,
      configuration: VideoControllerConfiguration(),
    );

    _subscriptions.add(
      player.stream.error.listen((event) {
        if (!mounted) return;
        showToast(
          context: context,
          builder: buildToast,
          location: ToastLocation.bottomLeft,
        );
        _leave();
      }),
    );

    _watchPlayback();
    _startStream();
  }

  Future<void> _leave() async {
    await _saveCurrentProgress();
    await PlayerOrientation.restorePortrait();
    if (mounted && Navigator.of(context).canPop()) context.pop();
  }

  void _setupDiscord() {
    if (isOffline) return;
    _discordSub?.cancel();

    final stream$ = Rx.combineLatest2<bool, Duration, (bool, Duration)>(
      player.stream.playing.startWith(player.state.playing),
      player.stream.duration.startWith(player.state.duration),
      (playing, duration) => (playing, duration),
    ).where((data) => data.$2 > Duration.zero).distinct();

    _discordSub = stream$.listen((data) async {
      final item = _item;
      final episode = item.episode;
      if (episode != null) {
        final show = await TMDB.tvShow(_item.mediaId);
        final ep = await TMDB.tvEpisode(
          _item.mediaId,
          episode.seasonNumber,
          episode.episodeNumber,
        );
        if (!mounted || _switching || !identical(item, _item)) return;
        Discord.updateStatus(
          show.name,
          '${ep.seasonNumber}x${ep.episodeNumber} ${ep.name}',
          player.state.position,
          data.$2,
          ep.stillUrl ?? '',
          data.$1,
        );
      } else {
        final movie = await TMDB.movie(_item.mediaId);
        if (!mounted || _switching || !identical(item, _item)) return;
        Discord.updateStatus(
          '${movie.title} (${movie.releaseDate.year})',
          movie.genres.map((item) => item.name).join(', '),
          player.state.position,
          data.$2,
          movie.images?.posters.first.url ?? '',
          data.$1,
        );
      }
    });
  }

  double _ratio() {
    final duration = player.state.duration.inMilliseconds;
    if (duration <= 0) return 0;
    return (player.state.position.inMilliseconds / duration).clamp(0.0, 1.0);
  }

  Future<void> _writeProgress(double value) async {
    final completion = WatchProgress.storedCompletion(value);
    if (_lastWrittenProgress == completion) return;
    _lastWrittenProgress = completion;
    try {
      if (isOffline) {
        final download = _item.stream?.download;
        if (download != null)
          await DownloadManager.setPlaybackProgress(download.id, completion);
        return;
      }
      if (_profileKey == null || _profileKey != BackendApi.profileCacheKey)
        return;
      await BackendApi.setProgress(
        _item.mediaId,
        mediaType,
        completion,
        season: _item.episode?.seasonNumber,
        episode: _item.episode?.episodeNumber,
      );
    } catch (_) {
      if (_lastWrittenProgress == completion) _lastWrittenProgress = null;
      // A failed save must not interrupt playback or trigger online fallback.
    }
  }

  Future<void> _saveCurrentProgress({bool duringSwitch = false}) async {
    if (_switching && !duringSwitch) return;
    if (player.state.duration <= Duration.zero) return;
    final ratio = _ratio();
    if (ratio <= 0 && !_finishedThisSession) return;
    await _writeProgress(_finishedThisSession ? 1 : ratio);
  }

  void saveProgressTask() {
    _saveProgress = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveCurrentProgress(),
    );
  }

  void _applyResume() {
    final progress = _item.progress ?? 0;
    if (_switching ||
        _resumeApplied ||
        progress <= 0 ||
        player.state.duration <= Duration.zero)
      return;
    _resumeApplied = true;
    player.seek(player.state.duration * progress.clamp(0, 1));
  }

  void _watchPlayback() {
    _subscriptions.add(
      player.stream.position.listen((position) {
        if (_switching) return;
        if (_finishedThisSession &&
            position.inSeconds <= 5 &&
            player.state.playing &&
            !player.state.completed) {
          _finishedThisSession = false;
          _writeProgress(0.01);
        }
        if (!_finishedThisSession && WatchProgress.isWatched(_ratio())) {
          _finishedThisSession = true;
          _writeProgress(1);
        }
      }),
    );
    _subscriptions.add(
      player.stream.completed.listen((done) {
        if (_switching) return;
        // End-of-file alone is not evidence of 90% progress.
        if (done &&
            !_finishedThisSession &&
            WatchProgress.isWatched(_ratio())) {
          _finishedThisSession = true;
          _writeProgress(1);
        }
      }),
    );
    _subscriptions.add(player.stream.duration.listen((_) => _applyResume()));
    _subscriptions.add(
      player.stream.tracks.listen((tracks) {
        if (_switching) return;
        applyPreferredTracks(
          audios: tracks.audio,
          subtitles: tracks.subtitle,
          audioLang: 'en',
          subtitleLang: 'en',
          preferAd: true,
          allowAd: true,
        );
        _applyResume();
      }),
    );
  }

  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: const Text('Stream failed to load'),
        subtitle: Text(selectedStream?.title ?? _item.stream?.title ?? 'Video'),
        trailing: PrimaryButton(
          size: ButtonSize.small,
          onPressed: () {
            overlay.close();
          },
          child: const Text('Retry'),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Future<void> _playEpisode(Episode next) async {
    if (_switching || isOffline || !mounted) return;
    setState(() => _switching = true);
    try {
      await player.pause();
      await _saveCurrentProgress(duringSwitch: true);
      if (!mounted) return;
      await _discordSub?.cancel();
      _item = PlaybackItem(mediaId: _item.mediaId, episode: next, progress: 0);
      mediaType = MediaType.show;
      _resumeApplied = false;
      _finishedThisSession = false;
      _lastWrittenProgress = null;
      selectedStream = null;
      await _startStream();
    } catch (_) {
      if (!mounted) return;
      setState(() => _switching = false);
      showToast(
        context: context,
        builder: buildToast,
        location: ToastLocation.bottomLeft,
      );
    }
  }

  Future<void> _startStream() async {
    try {
      final stream = await PlaybackSource.resolve(
        mediaId: _item.mediaId,
        episode: _item.episode,
        selected: _item.stream,
      );
      if (!mounted) return;
      if (stream == null) {
        await _leave();
        return;
      }
      selectedStream = stream;
      if (!isOffline &&
          _item.stream == null &&
          await ExternalPlayer.openTracked(
            stream: stream,
            mediaId: _item.mediaId,
            episode: _item.episode,
            label: stream.title,
          )) {
        if (mounted) await _leave();
        return;
      }
      await _mediaSession.open(
        Media(
          stream.url,
          extras: {
            'mediaId': _item.mediaId,
            'episode': _item.episode,
            'offline': isOffline,
            'title': stream.download?.displayTitle ?? stream.title,
            'subtitle': stream.download?.episodeLabel,
          },
        ),
        beforePlay: () async {
          if (!mounted) return;
          _switching = false;
          final tracks = player.state.tracks;
          applyPreferredTracks(
            audios: tracks.audio,
            subtitles: tracks.subtitle,
            audioLang: 'en',
            subtitleLang: 'en',
            preferAd: true,
            allowAd: true,
          );
          _applyResume();
        },
      );
      if (!mounted) return;
      setState(() => _switching = false);
      if (!isOffline) _setupDiscord();
    } catch (_) {
      if (!mounted) return;
      showToast(
        context: context,
        builder: buildToast,
        location: ToastLocation.bottomLeft,
      );
      await _leave();
    }
  }

  bool _matchesLanguage(String? language, String? title, String preferred) {
    final want = preferred.toLowerCase().trim();
    final lang = (language ?? '').toLowerCase().trim();
    final name = (title ?? '').toLowerCase();

    if (want.isEmpty) return false;

    const aliases = <String, Set<String>>{
      'en': {'en', 'eng', 'en-us', 'en-gb', 'english'},
      'eng': {'en', 'eng', 'en-us', 'en-gb', 'english'},
      'ja': {'ja', 'jpn', 'jp', 'japanese'},
      'jpn': {'ja', 'jpn', 'jp', 'japanese'},
      'ko': {'ko', 'kor', 'korean'},
      'zh': {'zh', 'chi', 'zho', 'chinese', 'cmn'},
      'es': {'es', 'spa', 'spanish'},
      'fr': {'fr', 'fra', 'fre', 'french'},
      'de': {'de', 'deu', 'ger', 'german'},
      'pt': {'pt', 'por', 'portuguese'},
      'ru': {'ru', 'rus', 'russian'},
      'it': {'it', 'ita', 'italian'},
    };

    final names = aliases[want] ?? {want};
    if (names.contains(lang) || lang.startsWith(want)) return true;
    if (names.any((n) => n.length > 2 && name.contains(n))) return true;
    return false;
  }

  bool _isCommentary(String? title) {
    final name = (title ?? '').toLowerCase();
    return name.contains('commentary') ||
        RegExp(r'\bcomment(ary)?\b').hasMatch(name);
  }

  bool _isAudioDescription(String? title, String? language) {
    final name = '${title ?? ''} ${language ?? ''}'.toLowerCase();
    return name.contains('audio description') ||
        name.contains('audio-description') ||
        name.contains('described') ||
        RegExp(r'\b(ad|vi|dvb-ad|sadh)\b').hasMatch(name) ||
        name.contains('descriptive');
  }

  T? pickTrack<T>({
    required List<T> tracks,
    required String preferred,
    required String? Function(T t) language,
    required String? Function(T t) title,
    bool preferCommentary = false,
    bool allowCommentary = true,
    bool preferAd = false,
    bool allowAd = true,
  }) {
    bool ok(T t) {
      final commentary = _isCommentary(title(t));
      final ad = _isAudioDescription(title(t), language(t));

      if (preferAd && !ad) return false;
      if (!allowAd && ad) return false;
      if (preferCommentary && !commentary) return false;
      if (!allowCommentary && commentary) return false;

      return _matchesLanguage(language(t), title(t), preferred);
    }

    final matches = tracks.where(ok).toList();
    if (matches.isEmpty && preferAd) {
      return pickTrack(
        tracks: tracks,
        preferred: preferred,
        language: language,
        title: title,
        preferCommentary: preferCommentary,
        allowCommentary: allowCommentary,
        preferAd: false,
        allowAd: allowAd,
      );
    }
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final aAd = _isAudioDescription(title(a), language(a));
      final bAd = _isAudioDescription(title(b), language(b));
      if (preferAd && aAd != bAd) return aAd ? -1 : 1;
      return 0;
    });
    return matches.first;
  }

  void applyPreferredTracks({
    required List<AudioTrack> audios,
    required List<SubtitleTrack> subtitles,
    required String audioLang,
    required String subtitleLang,
    bool preferCommentary = false,
    bool allowCommentary = false,
    bool preferAd = false,
    bool allowAd = false,
  }) {
    final audio = pickTrack<AudioTrack>(
      tracks: audios,
      preferred: audioLang,
      language: (t) => t.language,
      title: (t) => t.title,
      preferCommentary: preferCommentary,
      allowCommentary: allowCommentary,
      preferAd: preferAd,
      allowAd: allowAd,
    );
    if (audio != null) {
      player.setAudioTrack(audio);
    } else {
      if (audios.isNotEmpty) player.setAudioTrack(audios.first);
      print(
        'No $audioLang audio in ${audios.map((a) => '${a.language}/${a.title}').toList()}',
      );
    }

    final sub = pickTrack<SubtitleTrack>(
      tracks: subtitles,
      preferred: subtitleLang,
      language: (t) => t.language,
      title: (t) => t.title,
      preferCommentary: false,
      allowCommentary: true,
      preferAd: false,
      allowAd: true,
    );
    if (sub != null) {
      player.setSubtitleTrack(sub);
    }
  }

  Future<void> closeStream() async {
    print("Progress is: ${_ratio()}");
  }

  @override
  void dispose() {
    _saveCurrentProgress();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _saveProgress?.cancel();
    _discordSub?.cancel();
    if (!isOffline) Discord.resetStatus();
    controller.pictureInPicture.stop();
    player.dispose();
    PlayerOrientation.restorePortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        PlayerOrientation.restorePortrait();
      },
      child: PlaybackScope(
        playEpisode: _playEpisode,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: controller,
              controls: videoControls,
              fit: BoxFit.contain,
              aspectRatio: 16 / 9,
              pip: const PipConfig(
                autoEnter: true,
                preferredSize: Size(1920 / 5, 1080 / 5),
              ),
            ),
            if (_switching)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x80101018),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
