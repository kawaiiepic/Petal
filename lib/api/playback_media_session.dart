import 'package:media_kit/media_kit.dart';
import 'package:petal/api/playback_volume_store.dart';

/// Opens successive media on one native player, without a loud reset on open.
class PlaybackMediaSession {
  final Player player;
  final PlaybackVolumeStore volumeStore;
  bool _opened = false;
  bool _opening = false;
  PlaybackMediaSession(this.player, {PlaybackVolumeStore? volumeStore})
    : volumeStore = volumeStore ?? PlaybackVolumeStore.instance;

  Future<void> open(Media media, {Future<void> Function()? beforePlay}) async {
    if (_opening) throw StateError('A media transition is already in progress');
    _opening = true;
    try {
      final savedVolume = await volumeStore.load();
      final volume = _opened ? player.state.volume : savedVolume;
      final revision = volumeStore.revision;
      await player.open(media, play: false);
      // A user adjustment made while opening must win over the earlier value.
      final nextVolume = revision == volumeStore.revision
          ? volume
          : volumeStore.value ?? volume;
      await player.setVolume(nextVolume);
      await beforePlay?.call();
      await player.play();
      _opened = true;
    } finally {
      _opening = false;
    }
  }
}
