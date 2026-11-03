import 'dart:typed_data';

class LibraryImportFile {
  const LibraryImportFile({
    required this.name,
    required this.bytes,
    required this.count,
  });

  final String name;
  final Uint8List bytes;
  final int count;
}
