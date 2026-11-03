import 'dart:math';
import 'package:dio/dio.dart';

final _random = Random.secure();
String newRequestKey() => List.generate(16, (_) =>
    _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

/// Reuse the same key for one transport retry; never silently start a new action.
Future<Response<dynamic>> retryableWrite(
    Future<Response<dynamic>> Function(Options options) send, {String? requestKey}) async {
  final options = Options(headers: {'Idempotency-Key': requestKey ?? newRequestKey()});
  try {
    return await send(options);
  } on DioException catch (error) {
    if (!{DioExceptionType.connectionTimeout, DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout, DioExceptionType.connectionError}.contains(error.type)) rethrow;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return send(options);
  }
}
