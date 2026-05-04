import 'package:petal/api/trakt/models.dart';

class TraktWatchedShowWithProgress {
  final TraktShow? watchedShow;
  final Show? show;
  final TraktShowProgress showProgress;

  TraktWatchedShowWithProgress({required this.watchedShow, required this.show, required this.showProgress});
}
