import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SurpriseWatchlistButton extends StatelessWidget {
  const SurpriseWatchlistButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.watchlist,
      builder: (context, _, __) {
        final titles = UserLibrary.watchlistTitles();
        return PetalButton.secondary(
          onPressed: titles.isEmpty
              ? null
              : () {
                  final pick = titles[Random().nextInt(titles.length)];
                  context.push(
                    pick.type == MediaType.show
                        ? '/series?tmdb=${pick.tmdbId}'
                        : '/movie?tmdb=${pick.tmdbId}',
                  );
                },
          child: const Text(
            'Surprise me from my watchlist',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
