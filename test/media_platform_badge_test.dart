import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_platform_badge.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

import 'support/recording_adapter.dart';

void main() {
  final adapter = RecordingAdapter()
    ..respond = (request) {
      final path = request.queryParameters['url'] as String;
      final providers = {
        'results': {
          'GB': {
            'flatrate': [
              {'provider_name': 'Example Stream', 'logo_path': '/stream.png'},
            ],
          },
          'US': {
            'rent': [
              {'provider_name': 'Rental', 'logo_path': '/rent.png'},
            ],
          },
        },
      };
      if (path.startsWith('/tv/')) {
        return jsonBody({
          'networks': [
            {'name': 'Original TV', 'logo_path': '/original.png'},
          ],
          'watch/providers': providers,
        });
      }
      return jsonBody(providers);
    };
  setUpAll(() => BackendApi.dio = Dio()..httpClientAdapter = adapter);
  setUp(() {
    TMDB.clearCache();
    adapter.requests.clear();
  });

  test(
    'movie badge only uses a subscription platform for the local region',
    () async {
      final platform = await TMDB.mediaPlatform(
        42,
        MediaType.movie,
        region: 'gb',
      );
      expect(platform?.label, 'Streaming on Example Stream');
      expect(platform?.logoUrl, 'https://image.tmdb.org/t/p/w92/stream.png');
      expect(
        await TMDB.mediaPlatform(42, MediaType.movie, region: 'US'),
        isNull,
      );
      expect(await TMDB.mediaPlatform(42, MediaType.movie), isNull);
      expect(adapter.requests.length, 1);
    },
  );

  testWidgets(
    'poster centers only its subtitle and uses the original network logo',
    (tester) async {
      final item = CatalogItem.fromJson({
        'id': '42',
        'name': 'Test Series',
        'type': 'series',
        'poster': 'https://img.example/poster.jpg',
        'genres': ['Comedy'],
      });
      await tester.pumpWidget(
        ShadcnApp(
          home: Center(
            child: SizedBox(
              width: 130,
              height: 195,
              child: CatalogItemWidget(catalogItem: item, rank: 1),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Test Series'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Comedy')).textAlign,
        TextAlign.center,
      );
      expect(
        tester.widget<MediaCard>(find.byType(MediaCard)).semanticLabel,
        '1. Test Series Comedy',
      );
      expect(
        tester
            .widget<MediaPlatformBadge>(find.byType(MediaPlatformBadge))
            .platform
            .label,
        'Original network: Original TV',
      );
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
    },
  );
}
