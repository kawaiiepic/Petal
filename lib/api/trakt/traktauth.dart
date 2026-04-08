import 'dart:convert';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';

class TraktAuth {

  /// Step 1: Request device code
  static Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await TraktApi.dio.get(
      "${Api.ServerUrl}/trakt/device_code",
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data;
    } else {
      throw Exception('Failed to get device code: ${response.statusCode}');
    }
  }

  static Future<void> pollForAccessToken(
    String deviceCode,
    int interval,
    int expiresIn,
  ) async {
    // final url = "${Api.ServerUrl}/trakt/check_auth";
    // final endTime = DateTime.now().add(Duration(seconds: expiresIn));

    // while (DateTime.now().isBefore(endTime)) {
    //   await Future.delayed(Duration(seconds: interval));

    //   final res = await TraktApi.dio.post(
    //     url,
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({'code': deviceCode}),
    //   );

    //   if (res.statusCode == 200) {
    //     final data = jsonDecode(res.body);

    //     print(data);

    //     //Save
    //     // if (kIsWeb) {
    //     //   print("Running on Web!");
    //     // } else {
    //     //   final directory = await getApplicationCacheDirectory();
    //     //   var file = File('${directory.path}/trakt.json');

    //     //   file.writeAsString(jsonEncode(data));
    //     // }
    //     //
    //   } else if (res.statusCode == 400) {
    //     // Authorization pending, keep polling
    //     continue;
    //   } else {
    //     throw Exception('Polling failed: ${res.body}');
    //   }
    // }

    // throw Exception('Device code expired before approval');
  }
}
