import 'package:petal/api/api.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueryProxy {
  static const _enabledKey = 'proxy_queries_enabled';
  static const _urlKey = 'proxy_queries_url';

  static final ValueNotifier<bool> enabled = ValueNotifier(false);
  static final ValueNotifier<String> url = ValueNotifier(defaultUrl);

  static String get defaultUrl => '${Api.ServerUrl}/proxy?url=';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? false;
    url.value = prefs.getString(_urlKey) ?? defaultUrl;
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  static Future<void> setUrl(String value) async {
    final trimmed = value.trim().isEmpty ? defaultUrl : value.trim();
    url.value = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, trimmed);
  }

  static bool _alreadyProxied(String target) {
    final lower = target.toLowerCase();
    return lower.contains('blossomvale.dev') || lower.contains('localhost:8787');
  }

  static String wrap(String target) {
    if (!enabled.value) return target;
    if (_alreadyProxied(target)) return target;

    final template = url.value.trim().isEmpty ? defaultUrl : url.value.trim();
    final encoded = Uri.encodeComponent(target);

    if (template.contains('{url}')) {
      return template.replaceAll('{url}', encoded);
    }
    if (template.endsWith('url=') || template.endsWith('url=')) {
      return '$template$encoded';
    }
    if (template.endsWith('?') || template.endsWith('&')) {
      return '${template}url=$encoded';
    }
    if (template.contains('?')) {
      return '$template&url=$encoded';
    }
    return '${template.replaceAll(RegExp(r'/+\s*$'), '')}?url=$encoded';
  }

  static Uri wrapUri(String target) => Uri.parse(wrap(target));
}
