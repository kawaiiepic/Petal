import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/trakt_helper.dart';

class TraktAuth {
  /// Step 1: Request device code
  static Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await TraktApi.dio.get("${Api.ServerUrl}/trakt/deviceCode");

    if (response.statusCode == 200) {
      final data = response.data;
      return data;
    } else {
      throw Exception('Failed to get device code: ${response.statusCode}');
    }
  }

  static Future<void> pollForAccessToken(String deviceCode, int interval, int expiresIn) async {
    final url = "${Api.ServerUrl}/trakt/poll";
    final endTime = DateTime.now().add(Duration(seconds: expiresIn));

    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(Duration(seconds: interval));

      final res = await TraktApi.dio.post(url, queryParameters: {'Content-Type': 'application/json'}, data: {'code': deviceCode});

      if (res.statusCode == 200) {
        final data = res.data;

        TraktApi.authState.setTraktLoggedIn(true);

        return;

      } else if (res.statusCode == 201) {
        // Authorization pending, keep polling
        continue;
      } else {
        throw Exception('Polling failed: ${res.data}');
      }
    }

    throw Exception('Device code expired before approval');
  }
}
