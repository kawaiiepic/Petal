import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/models/library/collection_section.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/pages/collection_home_page.dart';
import 'package:petal/widgets/library/library_page_header.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionPage extends StatefulWidget {
  final CollectionSection? section;
  const CollectionPage({super.key, this.section});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  void initState() {
    super.initState();
    BackendCache.fetchWatchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final header = LibraryPageHeader(
          title: widget.section?.label ?? 'Collection',
          description: widget.section?.description ??
              'Pick up where you left off or find something you saved.',
          icon: LucideIcons.library,
          showAccount: true,
        );
    final content = CollectionHomePage(key: ValueKey(widget.section), section: widget.section);
    if (!TvLayout.isCompact(context)) {
      // Let the desktop shell's shared gradient show through the whole page.
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        Expanded(child: content),
      ]);
    }
    return Scaffold(headers: [header], child: content);
  }
}
