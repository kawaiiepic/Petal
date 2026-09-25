import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/library_import_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class TraktImportPage extends StatelessWidget {
  const TraktImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      headers: [
        AppBar(leading: [BackButton()], title: Text('Import library')),
      ],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: LibraryImportCard(),
      ),
    );
  }
}
