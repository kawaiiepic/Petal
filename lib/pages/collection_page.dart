import 'package:go_router/go_router.dart';
import 'package:petal/models/library/collection_section.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
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
    return Scaffold(
      headers: [
        LibraryPageHeader(
          title: widget.section?.label ?? 'Collection',
          description: widget.section?.description ??
              'Pick up where you left off or find something you saved.',
          icon: LucideIcons.library,
          action: widget.section == null ? null : PetalButton.ghost(
            onPressed: () => context.go('/collection'), child: const Text('All collections')),
          showAccount: true,
        ),
      ],
      child: CollectionHomePage(key: ValueKey(widget.section), section: widget.section),
    );
  }
}
