import 'dart:io';

import 'package:dio/dio.dart';

/// A partial file is appended only when the server confirms its range and
/// validator. Servers without range support safely restart the transfer.
abstract final class ResumableDownload {
  static Future<void> run({
    required Dio dio,
    required String url,
    required File file,
    required CancelToken cancelToken,
    required void Function(int, int) progress,
    required void Function(String?) validator,
    String? previousValidator,
  }) async {
    var offset = await file.exists() ? await file.length() : 0;
    if (previousValidator == null) offset = 0;
    final response = await dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        validateStatus: (status) =>
            status == 200 || status == 206 || status == 416,
        headers: {
          'Accept-Encoding': 'identity',
          if (offset > 0) 'Range': 'bytes=$offset-',
          if (offset > 0) 'If-Range': previousValidator,
        },
      ),
    );
    final currentValidator =
        response.headers.value('etag')?.startsWith('W/') == false
        ? response.headers.value('etag')
        : response.headers.value('last-modified');
    final range = response.headers.value('content-range');
    if (response.statusCode == 416) {
      await response.data!.stream.listen((_) {}).cancel();
      final total = int.tryParse(range?.replaceFirst('bytes */', '') ?? '');
      if (offset > 0 &&
          total == offset &&
          currentValidator == previousValidator) {
        progress(offset, offset);
        return;
      }
      if (offset == 0) throw StateError('Server rejected a full download.');
      return run(
        dio: dio,
        url: url,
        file: file,
        cancelToken: cancelToken,
        progress: progress,
        validator: validator,
      );
    }
    if (offset > 0 &&
        response.statusCode == 206 &&
        currentValidator != null &&
        currentValidator != previousValidator) {
      await response.data!.stream.listen((_) {}).cancel();
      return run(
        dio: dio,
        url: url,
        file: file,
        cancelToken: cancelToken,
        progress: progress,
        validator: validator,
      );
    }
    final match = range == null
        ? null
        : RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$').firstMatch(range);
    if (response.statusCode == 206 &&
        (match == null || int.parse(match.group(1)!) != offset)) {
      await response.data!.stream.listen((_) {}).cancel();
      throw StateError('Server returned an invalid download range.');
    }
    if (response.statusCode != 206) offset = 0;
    validator(
      response.headers.value('etag')?.startsWith('W/') == false
          ? response.headers.value('etag')
          : response.headers.value('last-modified'),
    );
    final length =
        int.tryParse(response.headers.value('content-length') ?? '') ?? 0;
    final total = match != null && match.group(3) != '*'
        ? int.parse(match.group(3)!)
        : (length > 0 ? offset + length : 0);
    final sink = file.openWrite(
      mode: offset > 0 ? FileMode.append : FileMode.write,
    );
    var received = offset;
    try {
      await for (final bytes in response.data!.stream) {
        if (cancelToken.isCancelled) throw cancelToken.cancelError!;
        sink.add(bytes);
        received += bytes.length;
        progress(received, total);
      }
      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
      if (total > 0 && received != total)
        throw StateError('Download ended before the file was complete.');
    } finally {
      await sink.flush();
      await sink.close();
    }
  }
}
