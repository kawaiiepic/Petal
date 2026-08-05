import 'dart:convert';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/authstate.dart';
import 'package:petal/api/trakt/activity.dart';
import 'package:petal/api/trakt/models.dart';
import 'package:petal/api/trakt/trakt_cache.dart';
import 'package:petal/api/trakt/trakt_class.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/models/trakt/profile/extended_profile.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class BackendApi {
  static late final Dio dio;
  static late final PersistCookieJar cookieJar;
  static final String secretKey = "";
  static final AuthState authState = AuthState();

  // static final ValueNotifier<bool> validSession = ValueNotifier(false);

  static Future<void> init() async {
    prepareCookieManager();
  }

  static Future<void> prepareCookieManager() async {
    dio = Dio();
    final directory = await getApplicationCacheDirectory();
    print(directory.path);
    cookieJar = PersistCookieJar(ignoreExpires: true, storage: FileStorage("${directory.path}/.cookies/"));
    dio.interceptors.add(CookieManager(cookieJar));
  }

  static Future<bool> verifySession() async {
    print("Verifying session");
    try {
      final response = await dio.get("${Api.ServerUrl}/users/verify");
      print("Response code for verify.");
      print(response.data);

      if (response.data["success"] == true) {
        authState.setInitializing(false);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Expected case: no valid session — just treat as logged out
        print("No valid session");
      } else {
        print("Error verifying session: $e");
      }
    }
    authState.setInitializing(false);
    return false;
  }

  static Future<void> signOut() async {
    await cookieJar.deleteAll();
    authState.setLoggedIn(false);
  }

  static Future<void> addUserAddon(String manifestUrl, bool forced) async {
    final addon = {"manifest_url": manifestUrl, "forced": forced, "config": "string"};

    await BackendApi.dio.post("${Api.ServerUrl}/addons", data: addon);

    ApiCache.refreshAddons();
  }

  static Future<void> addAddonResource(String addonId, String resource) async {
    await BackendApi.dio.post("${Api.ServerUrl}/addons/$addonId/resources/$resource");
  }

  static Future<void> delAddonResource(String addonId, String resource) async {
    await BackendApi.dio.delete("${Api.ServerUrl}/addons/$addonId/resources/$resource");
  }

  static Future<List<Addon>> fetchUserAddons() async {
    final url = '${Api.ServerUrl}/addons';
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final data = response.data;
      final addonsJson = data['result'] as List;

      // map to list of futures
      final futures = addonsJson.map((json) async {
        var addon = Addon.fromJson(json);
        await addon.fetchManifest();
        return addon;
      }).toList();

      // wait for all futures to complete
      final addons = await Future.wait(futures);
      return addons;
    } else {
      throw Exception('Failed to fetch addons');
    }
  }

  static Future<List<Profile>> profiles() async {
    final url = '${Api.ServerUrl}/profiles';
    final response = await dio.get(url);

    final json = response.data['result'] as List;

    // map to list of futures
    final futures = json.map((json) async {
      var addon = Profile.fromJson(json);
      return addon;
    }).toList();

    // wait for all futures to complete
    final addons = await Future.wait(futures);
    return addons;
  }

  static Future<void> addProfile(String name) async {
    final url = '${Api.ServerUrl}/profiles';
    await dio.post(url, data: {"name": name, "avatar": "builtin:1"});
  }

  static Future<List<MediaState>> continueWatching() async {
    if (authState.selectedProfile == null) return [];
    final url = '${Api.ServerUrl}/track/continue/${authState.selectedProfile?.id}';
    final response = await dio.get(url);

    final json = response.data['result'] as List;

    print(json);

    // map to list of futures
    final futures = json.map((json) async {
      var addon = MediaState.fromJson(json);
      return addon;
    }).toList();

    // wait for all futures to complete
    final addons = await Future.wait(futures);
    return addons;
  }

    static Future<void> setState(String name) async {
    final url = '${Api.ServerUrl}/track/state/';
    await dio.post(url, data: {"name": name, "avatar": "builtin:1"});
  }
}
