import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:flutter/material.dart';

class TraktFuture {
  static Future<List<TraktShow>> _fetchHistory = Future.value([]);

  static Future<List<TraktShow>> fetchHistory({int limit = 10}) async {
    if ((await _fetchHistory).isNotEmpty) return _fetchHistory;
    print("Fetching History!!!");
    final nextUp = await TraktApi.getNextUp(MediaType.show);

    Future<TraktNextUpItem?> buildNextUp(TraktShow show) async {
      if (show.traktId == null) return null;

      final progress = await TraktApi.fetchShowProgress(show.traktId!);

      final next = progress.nextEpisode;
      if (next == null) return null;
      return TraktNextUpItem(show: show, season: next['season'], episode: next['number'], title: next['title'], progress: progress.completed);
    }

    var i = 0;
    List<TraktShow> shows = [];

    for (var item in nextUp) {
      if (i > limit) {
        continue;
      }
      var nextUpComplete = await buildNextUp(item.show);
      if (nextUpComplete != null) {
        print(nextUpComplete.show.title);
        shows.add(nextUpComplete.show);

        i++;
      }
    }

    return _fetchHistory = Future.value(shows);
  }
}
