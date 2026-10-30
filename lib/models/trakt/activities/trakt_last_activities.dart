import 'package:petal/models/trakt/activities/trakt_account_activities.dart';
import 'package:petal/models/trakt/activities/trakt_comment_activities.dart';
import 'package:petal/models/trakt/activities/trakt_episode_activities.dart';
import 'package:petal/models/trakt/activities/trakt_list_activities.dart';
import 'package:petal/models/trakt/activities/trakt_movie_activities.dart';
import 'package:petal/models/trakt/activities/trakt_season_activities.dart';
import 'package:petal/models/trakt/activities/trakt_show_activities.dart';
import 'package:petal/models/trakt/activities/trakt_timestamp_activity.dart';

class TraktLastActivities {
  final DateTime all;
  final TraktMovieActivities movies;
  final TraktEpisodeActivities episodes;
  final TraktShowActivities shows;
  final TraktSeasonActivities seasons;
  final TraktCommentActivities comments;
  final TraktListActivities lists;
  final TraktTimestampActivity watchlist;
  final TraktTimestampActivity favorites;
  final TraktAccountActivities account;
  final TraktTimestampActivity savedFilters;
  final TraktTimestampActivity notes;

  TraktLastActivities({
    required this.all,
    required this.movies,
    required this.episodes,
    required this.shows,
    required this.seasons,
    required this.comments,
    required this.lists,
    required this.watchlist,
    required this.favorites,
    required this.account,
    required this.savedFilters,
    required this.notes,
  });

  factory TraktLastActivities.fromJson(Map<String, dynamic> json) {
    return TraktLastActivities(
      all: DateTime.parse(json['all']),
      movies: TraktMovieActivities.fromJson(json['movies']),
      episodes: TraktEpisodeActivities.fromJson(json['episodes']),
      shows: TraktShowActivities.fromJson(json['shows']),
      seasons: TraktSeasonActivities.fromJson(json['seasons']),
      comments: TraktCommentActivities.fromJson(json['comments']),
      lists: TraktListActivities.fromJson(json['lists']),
      watchlist: TraktTimestampActivity.fromJson(json['watchlist']),
      favorites: TraktTimestampActivity.fromJson(json['favorites']),
      account: TraktAccountActivities.fromJson(json['account']),
      savedFilters: TraktTimestampActivity.fromJson(json['saved_filters']),
      notes: TraktTimestampActivity.fromJson(json['notes']),
    );
  }
}
