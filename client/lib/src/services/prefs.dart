import "package:shared_preferences/shared_preferences.dart";

import "service.dart";

class PreferencesService extends Service {
  late final SharedPreferencesWithCache _plugin;

  @override
  Future<void> init() async {
    _plugin = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  set name(String value) => _plugin.setString("name", value);
  String? get name => _plugin.getString("name");

  set uri(String value) => _plugin.setString("uri", value);
  String? get uri => _plugin.getString("uri");

  set animations(bool value) => _plugin.setBool("animations", value);
  bool get animations => _plugin.getBool("animations") ?? false;
}
