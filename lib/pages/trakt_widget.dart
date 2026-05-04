import 'package:petal/models/catalog_item.dart';
import 'package:petal/pages/trakt_next_up.dart';
import 'package:flutter/material.dart';

typedef ItemHoverCallback = void Function(CatalogItem? item, String? background);

class NextUpRow extends StatefulWidget {
  const NextUpRow({super.key});

  @override
  State<NextUpRow> createState() => _NextUpRowState();
}

class _NextUpRowState extends State<NextUpRow> {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(children: const [TraktNextUp(key: ValueKey("traktNextUp"))]),
    );
  }
}
