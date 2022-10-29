import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtil {
  static SharedPreferences? _instance;

  static Future<SharedPreferences> getInstance() async {
    return _instance ??= await SharedPreferences.getInstance();
  }
}
