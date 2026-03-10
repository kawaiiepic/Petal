import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/models/trakt/profile/extended_profile.dart';
import 'package:http/http.dart';

class Trakt {
  static Future<ExtendedProfile> userProfile() async {
    final token = await TraktAuth.getAccessToken();
    var url = Uri.https('api.trakt.tv', '/users/me', {'extended': 'full'});
    var response = await get(url, headers: {'Authorization': 'Bearer $token', 'trakt-api-key': TraktAuth.clientId});

    if (response.statusCode == 200) {
      final profile = profileFromJson(response.body);

      return profile;
    } else {
      throw Exception();
    }
  }
}
