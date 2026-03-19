import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:flutter/material.dart';

class StillPoster extends StatefulWidget {
  final String tmdb;
  final int season;
  final int episode;

  const StillPoster({super.key, required this.tmdb, required this.season, required this.episode});

  @override
  State<StatefulWidget> createState() => _StillPosterState();
}

class _StillPosterState extends State<StillPoster> {
  late final Future<ImageProvider> _still;
  var focused = false;

  @override
  void initState() {
    _still = TMDB.still(widget.tmdb, widget.season, widget.episode).then((bytes) => MemoryImage(bytes));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _still,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return Container();
      print("Rebuilding inside FutureBuilder");
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Ink.image(
              image: snapshot.data!,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onHover: (hovered) {
                  if (focused != hovered) {
                    setState(() => focused = hovered);
                  }
                },
                onTap: () {
                  // click action
                },
              ),
            ),

            if (focused)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
