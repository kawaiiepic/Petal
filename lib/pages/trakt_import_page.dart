import 'package:file_picker/file_picker.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/trakt/trakt_import.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class TraktImportPage extends StatefulWidget {
  const TraktImportPage({super.key});

  @override
  State<TraktImportPage> createState() => _TraktImportPageState();
}

class _TraktImportPageState extends State<TraktImportPage> {
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip', 'json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _status = 'Could not read ${file.name}.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Importing ${file.name}…';
    });
    try {
      final report = await TraktImport.importFile(name: file.name, bytes: bytes);
      setState(() => _status = report.summary);
      Misc.sendNotification(const Text('Trakt import'), Text(report.summary));
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: const Text('Import from Trakt')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Text(
              'Export from trakt.tv → Settings → Data → Export now. Then pick the ZIP here, or a single history/watchlist/ratings JSON file.',
            ),
            Button.primary(
              onPressed: _busy ? null : _pick,
              child: Text(_busy ? 'Importing…' : 'Choose export file'),
            ),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}
