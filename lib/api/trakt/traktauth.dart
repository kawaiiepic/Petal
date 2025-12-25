import 'dart:convert';
import 'package:http/http.dart' as http;

class TraktAuth {
  static const clientId = '554be9097f452fa2b06990d8d0bc8fad858afa452537c2aaf234d4769ba76b8f';
  static const clientSecret = 'c981ace23f790bfb1d868dca0f8cd46e48d4032228f125f3762e0defdc9c65ad';
  static const deviceCodeUrl = 'https://api.trakt.tv/oauth/device/code';
  static const tokenUrl = 'https://api.trakt.tv/oauth/device/token';

  static const accessToken = 'f4850694d1fde7c124abb6db076bede337af8806ad4a83fccac9082f2fc47288';

  static Future<String> getAccessToken() async {
    return accessToken;
  }

  /// Step 1: Request device code
  static Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await http.post(Uri.parse(deviceCodeUrl), body: {'client_id': clientId});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // data contains device_code, user_code, verification_url, expires_in, interval
      return data;
    } else {
      throw Exception('Failed to get device code: ${response.statusCode}');
    }
  }

  static Future<String> pollForAccessToken(String deviceCode, int interval, int expiresIn) async {
    final url = Uri.parse(tokenUrl);
    final endTime = DateTime.now().add(Duration(seconds: expiresIn));

    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(Duration(seconds: interval));

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'trakt-api-version': '2', 'trakt-api-key': clientId},
        body: jsonEncode({'code': deviceCode, 'client_id': clientId, 'client_secret': clientSecret}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['access_token']; // Success!
      } else if (res.statusCode == 400) {
        // Authorization pending, keep polling
        continue;
      } else {
        throw Exception('Polling failed: ${res.body}');
      }
    }

    throw Exception('Device code expired before approval');
  }
}
