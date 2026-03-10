import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TraktAuth {
  static const deviceCodeUrl = 'https://api.trakt.tv/oauth/device/code';
  static const tokenUrl = 'https://api.trakt.tv/oauth/device/token';

  /// Step 1: Request device code
  static Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await http.post(Uri.parse(deviceCodeUrl), body: {'client_id': TraktApi.clientId});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to get device code: ${response.body}');
    }
  }

  static Future<String> pollForAccessToken(String deviceCode, int interval, int expiresIn) async {
    final url = Uri.parse(tokenUrl);
    final endTime = DateTime.now().add(Duration(seconds: expiresIn));

    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(Duration(seconds: interval));

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'trakt-api-version': '2', 'trakt-api-key': TraktApi.clientId},
        body: jsonEncode({'code': deviceCode, 'client_id': TraktApi.clientId, 'client_secret': TraktApi.clientSecret}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        //Save
        if (kIsWeb) {
          print("Running on Web!");
        } else {
          final directory = await getApplicationCacheDirectory();
          var file = File('${directory.path}/trakt.json');

          file.writeAsString(jsonEncode(data));
        }

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
