import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamPlayer extends StatefulWidget {
  final int mediaId;
  final Episode? episode;
  final StreamItem? stream;
  final double? progress;
  const StreamPlayer({super.key, required this.mediaId, required this.episode, this.stream, this.progress});

  @override
  State<StatefulWidget> createState() => StreamPlayerState();
}

class StreamPlayerState extends State<StreamPlayer> {
  MediaType mediaType = MediaType.movie;
  late final player = Player(configuration: PlayerConfiguration());
  late final VideoController controller;
  late final StreamItem selectedStream;
  bool zoomVideo = false;

  Timer? _saveProgress;

  @override
  void initState() {
    super.initState();

    if (widget.episode != null) mediaType = MediaType.show;

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    saveProgressTask();

    controller = VideoController(player, configuration: VideoControllerConfiguration());

    player.stream.error.listen((event) {
      showToast(context: context, builder: buildToast, location: ToastLocation.bottomLeft);
      if (mounted) context.pop();
    });

    _startStream();
  }

  void saveProgressTask() {
    _saveProgress = Timer.periodic(const Duration(seconds: 30), (_) {
      BackendApi.setProgress(
        widget.mediaId,
        mediaType,
        player.state.position.inMinutes / player.state.duration.inMinutes,
        season: widget.episode?.seasonNumber,
        episode: widget.episode?.episodeNumber,
      );
    });
  }

  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: const Text('Stream failed to load'),
        subtitle: Text(selectedStream.title),
        trailing: PrimaryButton(
          size: ButtonSize.small,
          onPressed: () {
            // Close the toast programmatically when clicking Undo.
            overlay.close();
          },
          child: const Text('Retry'),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Future<void> _startStream() async {
    final mediaImdb = widget.episode != null ? (await TMDB.tvShow(widget.mediaId)).imdbId : (await TMDB.movie(widget.mediaId)).imdbId;

    final streams = await StreamApi.fetchStreams(mediaImdb!, widget.episode);
    final stream = widget.stream ?? StreamApi.autoSelectStream(streams);

    if (stream == null) {
      if (mounted) context.pop();
      return;
    }

    selectedStream = stream;

    print(selectedStream.url);

    await player.open(Media(selectedStream.url, extras: {'mediaId': widget.mediaId, 'episode': widget.episode}));

    player.stream.tracks.listen((event) {
      applyPreferredTracks(
        audios: event.audio,
        subtitles: event.subtitle,
        audioLang: 'en',
        subtitleLang: 'en',
        preferAd: true,
        allowAd: true,
        preferCommentary: false,
        allowCommentary: false,
      );

      if (widget.progress != null) player.seek(player.state.duration * widget.progress!);
    });

    player.stream.playing.listen((bool playing) {
      if (playing) {
        // Playing.
      } else {
        // Paused.
      }
    });
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
    return name.contains('commentary') || RegExp(r'\bcomment(ary)?\b').hasMatch(name);
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
      player.setAudioTrack(audios.first);
      print('No $audioLang audio in ${audios.map((a) => '${a.language}/${a.title}').toList()}');
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
    print("Progress is: ${player.state.position.inMinutes / player.state.duration.inMinutes}");
  }

  @override
  void dispose() {
    print("Disposing...");
    Discord.resetStatus();
    controller.pictureInPicture.stop();
    player.dispose();
    // closeStream();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: videoControls,
      fit: BoxFit.contain,
      aspectRatio: 16 / 9,
      pip: const PipConfig(autoEnter: true, preferredSize: Size(1920 / 5, 1080 / 5)),
    );
  }
}
