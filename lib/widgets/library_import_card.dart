import 'package:file_picker/file_picker.dart';
import 'package:petal/api/library_import.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryImportCard extends StatefulWidget {
  const LibraryImportCard({super.key});

  @override
  State<LibraryImportCard> createState() => _LibraryImportCardState();
}

class _LibraryImportCardState extends State<LibraryImportCard> {
  ImportSource _source = ImportSource.auto;
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip', 'json', 'csv'],
    );
    if (file == null) return;

    setState(() {
      _busy = true;
      _status = 'Importing ${file.name}…';
    });
    try {
      final bytes = await file.readAsBytes();
      final report = await LibraryImport.importFile(name: file.name, bytes: bytes, source: _source);
      setState(() => _status = report.summary);
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            const Basic(
              leading: Icon(LucideIcons.import),
              leadingAlignment: Alignment.center,
              title: Text('Import library'),
              subtitle: Text('Trakt, Letterboxd, Simkl, or a generic JSON/CSV. Existing titles are left alone.'),
            ),
            Select<ImportSource>(
              value: _source,
              itemBuilder: (context, item) => Text(switch (item) {
                ImportSource.auto => 'Auto detect',
                ImportSource.trakt => 'Trakt',
                ImportSource.letterboxd => 'Letterboxd',
                ImportSource.simkl => 'Simkl',
                ImportSource.generic => 'Generic JSON',
              }),
              popup: SelectPopup(
                items: SelectItemList(
                  children: [
                    for (final source in ImportSource.values)
                      SelectItemButton(
                        value: source,
                        child: Text(switch (source) {
                          ImportSource.auto => 'Auto detect',
                          ImportSource.trakt => 'Trakt',
                          ImportSource.letterboxd => 'Letterboxd',
                          ImportSource.simkl => 'Simkl',
                          ImportSource.generic => 'Generic JSON',
                        }),
                      ),
                  ],
                ),
              ),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _source = value);
                    },
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
