import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/pages/collection_home_page.dart';
import 'package:petal/widgets/library/library_page_header.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

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
          title: 'Collection',
          description:
              'Pick up where you left off or find something you saved.',
          icon: LucideIcons.library,
          showAccount: true,
        ),
      ],
      child: const CollectionHomePage(),
    );
  }
}
