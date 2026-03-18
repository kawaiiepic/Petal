import 'package:blssmpetal/api/trakt/models.dart';

class TraktWatchedShowWithProgress {
  final TraktShow? watchedShow;
  final Show? show;
  final TraktShowProgress showProgress;
  final List<TraktSeason> seasons;

  TraktWatchedShowWithProgress({required this.watchedShow, required this.show, required this.showProgress, required this.seasons});
}
