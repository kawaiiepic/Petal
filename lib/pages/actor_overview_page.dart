import 'package:petal/api/api.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/tmdb/tmdb_person.dart';
import 'package:petal/widgets/overview/filmography_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class ActorOverviewPage extends StatefulWidget {
  final int personId;

  const ActorOverviewPage({super.key, required this.personId});

  @override
  State<ActorOverviewPage> createState() => _ActorOverviewPageState();
}

class _ActorOverviewPageState extends State<ActorOverviewPage> {
  late Future<TmdbPerson> _person;

  @override
  void initState() {
    super.initState();
    _person = TMDB.person(widget.personId);
  }

  @override
  void didUpdateWidget(covariant ActorOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId) _person = TMDB.person(widget.personId);
  }

  String? _formatAge(String? birthday, String? deathday) {
    if (birthday == null) return null;
    final born = DateTime.tryParse(birthday);
    if (born == null) return null;
    final end = deathday != null
        ? DateTime.tryParse(deathday) ?? DateTime.now()
        : DateTime.now();
    int age = end.year - born.year;
    if (end.month < born.month ||
        (end.month == born.month && end.day < born.day))
      age--;
    return deathday != null ? '$age (age at death)' : '$age years old';
  }

  double get _labelSize =>
      Device.screenType == ScreenType.desktop ? 10.sp : 13.sp;
  double get _bodySize =>
      Device.screenType == ScreenType.desktop ? 12.sp : 14.sp;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbPerson>(
      key: ValueKey(widget.personId),
      future: _person,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && !snapshot.hasError) {
          final person = snapshot.data!;

          final filmography = [...(person.movieCredits?.cast ?? [])]
            ..sort((a, b) => b.releaseYear.compareTo(a.releaseYear));

          final age = _formatAge(person.birthday, person.deathday);

          return Container(
            color: Theme.of(context).colorScheme.background,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SafeArea(bottom: false,
                  child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(children: [
                      PetalButton.ghost(onPressed: () => Navigator.of(context).maybePop(),
                        child: const Icon(LucideIcons.chevronLeft, size: 22)),
                      Expanded(child: Text(person.name, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: _bodySize))),
                    ]),
                  ),
                )),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(width: 120, height: 170,
                                child: MediaArtwork(imageUrl: person.profilePath == null
                                  ? null : Api.proxyImage('https://image.tmdb.org/t/p/w342${person.profilePath}'))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style: TextStyle(
                                      fontSize:
                                          Device.screenType ==
                                              ScreenType.desktop
                                          ? 15.sp
                                          : 20.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (person.knownForDepartment != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      person.knownForDepartment!,
                                      style: TextStyle(
                                        fontSize: _labelSize,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                  if (age != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Age',
                                      style: TextStyle(
                                        fontSize: _labelSize,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      age,
                                      style: TextStyle(fontSize: _bodySize),
                                    ),
                                  ],
                                  if (person.placeOfBirth != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Born in',
                                      style: TextStyle(
                                        fontSize: _labelSize,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      person.placeOfBirth!,
                                      style: TextStyle(fontSize: _bodySize),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (person.biography != null &&
                            person.biography!.trim().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            style: TextStyle(
                              fontSize: Device.screenType == ScreenType.desktop
                                  ? 13.sp
                                  : 17.sp,
                            ),
                            'Biography',
                          ).h4,
                          const SizedBox(height: 8),
                          Text(
                            person.biography!,
                            style: TextStyle(fontSize: _bodySize, height: 1.5),
                          ),
                        ],

                        if (filmography.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            style: TextStyle(
                              fontSize: Device.screenType == ScreenType.desktop
                                  ? 13.sp
                                  : 17.sp,
                            ),
                            'Known For',
                          ).h4,
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filmography.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 110,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.5,
                                ),
                            itemBuilder: (context, i) =>
                                FilmographyCard(credit: filmography[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(child: SafeArea(child: Column(children: [
          Align(alignment: Alignment.centerLeft,
            child: PetalButton.ghost(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Icon(LucideIcons.chevronLeft, size: 22))),
          Expanded(child: Center(child: snapshot.hasError
            ? Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
                const Text('Could not load actor details.'),
                PetalButton.secondary(
                  onPressed: () => setState(() => _person = TMDB.person(widget.personId)),
                  child: const Text('Try again')),
              ])
            : const PetalActivityIndicator())),
        ])));
      },
    );
  }
}
