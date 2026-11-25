import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static final darkScheme = ColorSchemes.darkGray.pink.copyWith(
    background: () => const Color(0xFF100C15),
    card: () => const Color(0xFF1B1423),
    popover: () => const Color(0xFF22192B),
    secondary: () => const Color(0xFF291D35),
    muted: () => const Color(0xFF251D2D),
    accent: () => const Color(0xFF362545),
    border: () => const Color(0xFF3C3046),
    input: () => const Color(0xFF3C3046),
  );

  static final desktopDarkScheme = ColorSchemes.darkGray.blue.copyWith(
    background: () => const Color(0xFF101113),
    card: () => const Color(0xFF1B1D20),
    popover: () => const Color(0xFF25272B),
  );

  static const _prefsKey = 'theme_mode';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    mode.value = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.name);
  }
}
