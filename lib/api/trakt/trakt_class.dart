import 'package:blssmpetal/api/trakt/models.dart';

class TraktWatchedShowWithProgress {
  final TraktShow? watchedShow;
  final Show? show;
  final TraktShowProgress showProgress;

  TraktWatchedShowWithProgress({required this.watchedShow, required this.show, required this.showProgress});
}
