import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/person_cast_credit.dart';
import 'package:petal/models/tmdb/tmdb_person.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/widgets/overview/filmography_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ActorOverviewPage extends StatefulWidget {
  final int personId;
  const ActorOverviewPage({super.key, required this.personId});
  @override
  State<ActorOverviewPage> createState() => _ActorOverviewPageState();
}

class _ActorOverviewPageState extends State<ActorOverviewPage> {
  late Future<TmdbPerson> _person;
  MediaType? _filter;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _person = TMDB.person(widget.personId);
  }

  @override
  void didUpdateWidget(covariant ActorOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId) {
      _person = TMDB.person(widget.personId);
      _filter = null;
      _expanded = false;
    }
  }

  String? _age(TmdbPerson person) {
    final born = DateTime.tryParse(person.birthday ?? '');
    if (born == null) return null;
    final end = DateTime.tryParse(person.deathday ?? '') ?? DateTime.now();
    final age = end.year - born.year -
      ((end.month < born.month || (end.month == born.month && end.day < born.day)) ? 1 : 0);
    return person.deathday == null || person.deathday!.isEmpty ? '$age years old' : '$age at death';
  }

  Widget _back(BuildContext context) => Align(alignment: Alignment.centerLeft,
    child: PetalButton.ghost(
      onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/search'); } },
      child: const Icon(LucideIcons.chevronLeft, size: 22)));

  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)));

  Widget _hero(TmdbPerson person, bool compact) {
    final colors = Theme.of(context).colorScheme;
    final portrait = person.profilePath;
    final url = portrait == null ? null : Api.proxyImage('https://image.tmdb.org/t/p/w500$portrait');
    return Stack(children: [
      if (url != null) Positioned.fill(child: IgnorePointer(child: Opacity(opacity: .16,
        child: MediaArtwork(imageUrl: url, fit: BoxFit.cover)))),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [colors.background.withValues(alpha: .25), colors.background])))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, spacing: compact ? 16 : 28,
          children: [
            ClipOval(child: SizedBox.square(dimension: compact ? 108 : 174,
              child: MediaArtwork(imageUrl: url))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
              Text(person.knownForDepartment == 'Acting' ? 'ACTOR' :
                (person.knownForDepartment ?? 'Person').toUpperCase(),
                style: TextStyle(fontSize: 11, letterSpacing: 1.8, color: colors.mutedForeground,
                  fontWeight: FontWeight.w700)),
              Text(person.name, style: TextStyle(fontSize: compact ? 29 : 48,
                height: 1.05, fontWeight: FontWeight.w800)),
              if (_age(person) case final age?) Text(age,
                style: TextStyle(color: colors.mutedForeground)),
              if (person.placeOfBirth?.isNotEmpty ?? false)
                Text(person.placeOfBirth!, style: TextStyle(color: colors.mutedForeground, fontSize: 13)),
            ])),
          ]),
      ),
    ]);
  }

  Widget _grid(List<PersonCastCredit> credits, bool compact) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 145 : 168,
        mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: .55),
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        return FilmographyCard(key: ValueKey((credit.mediaType, credit.id)), credit: credit);
      },
    ));

  Widget _filterButton(MediaType? value, String label) {
    void select() => setState(() => _filter = value);
    return _filter == value
      ? PetalButton.primary(onPressed: select, child: Text(label))
      : PetalButton.secondary(onPressed: select, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<TmdbPerson>(
      key: ValueKey(widget.personId), future: _person,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return Column(children: [
            SafeArea(bottom: false, child: _back(context)),
            Expanded(child: Center(child: snapshot.hasError
              ? Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
                const Text('Could not load actor details.'),
                PetalButton.secondary(onPressed: () => setState(() => _person = TMDB.person(widget.personId)),
                  child: const Text('Try again')),
              ]) : const PetalActivityIndicator())),
          ]);
        }
        final person = snapshot.data!;
        final unique = <(MediaType, int), PersonCastCredit>{};
        for (final credit in person.credits) {
          if (credit.id > 0) unique.putIfAbsent((credit.mediaType, credit.id), () => credit);
        }
        final credits = unique.values.toList()..sort((a,b) => b.releaseDate.compareTo(a.releaseDate));
        final known = unique.values.where((c) => c.posterPath != null).toList();
        final filtered = credits.where((c) => _filter == null || c.mediaType == _filter).toList();
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: SafeArea(bottom: false, child: _back(context))),
          SliverToBoxAdapter(child: _hero(person, compact)),
          if (known.isNotEmpty) ...[
            SliverToBoxAdapter(child: _heading('Featured credits')),
            SliverToBoxAdapter(child: SizedBox(height: 208,
              child: ListView.separated(scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: known.length.clamp(0, 8).toInt(),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 124, child: FilmographyCard(credit: known[i]))))),
          ],
          if (person.biography?.trim().isNotEmpty ?? false) ...[
            SliverToBoxAdapter(child: _heading('About')),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(person.biography!, maxLines: _expanded ? null : 5,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(color: colors.foreground, height: 1.5, fontSize: 14)),
                PetalButton.ghost(onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Read more', style: TextStyle(color: colors.foreground))),
              ]))),
          ],
          SliverToBoxAdapter(child: _heading('Filmography')),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _filterButton(null, 'All'),
              _filterButton(MediaType.movie, 'Movies'),
              _filterButton(MediaType.show, 'TV Shows'),
            ]))),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Text('No credits found.')))
          else _grid(filtered, compact),
          SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.viewPaddingOf(context).bottom + (compact ? 82 : 0))),
        ]);
      },
    );
  }
}
