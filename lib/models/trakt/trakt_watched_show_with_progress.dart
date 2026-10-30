import 'package:petal/models/trakt/show.dart';
import 'package:petal/models/trakt/trakt_show.dart';
import 'package:petal/models/trakt/trakt_show_progress.dart';

class TraktWatchedShowWithProgress {
  final TraktShow? watchedShow;
  final Show? show;
  final TraktShowProgress showProgress;

  TraktWatchedShowWithProgress({
    required this.watchedShow,
    required this.show,
    required this.showProgress,
  });
}
