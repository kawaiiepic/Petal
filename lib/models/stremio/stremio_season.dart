import 'package:blssmpetal/models/stremio/stremio_episode.dart';

class StremioSeason {
  final int number;
  final List<StremioEpisode> episodes;

  StremioSeason({required this.number, required this.episodes});
}
