import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  FutureOr<ResponseBody> Function(RequestOptions)? respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond == null ? jsonBody({'result': []}) : await respond!(options);
  }

  @override
  void close({bool force = false}) {}

  int count(String path) => requests.where((r) => r.path.contains(path)).length;
}

ResponseBody jsonBody(Object data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
