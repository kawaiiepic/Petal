import 'package:petal/models/trakt/movie.dart';
import 'package:petal/models/trakt/show.dart';

class Search {
  final String type;
  final double? score;
  final Movie? movie;
  final Show? show;

  Search({required this.type, required this.score, this.movie, this.show});

  factory Search.fromJson(Map<String, dynamic> json) {
    return Search(
      type: json['type'],
      score: (json['score'] as num?)?.toDouble(),
      movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
      show: json['show'] != null ? Show.fromJson(json['show']) : null,
    );
  }
}
