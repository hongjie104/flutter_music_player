import 'package:flutter/material.dart';
import 'package:flutter_music_player/utils/shared_preference_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 集齐了７色：红橙黄绿青蓝紫
enum ColorStyle { blue, pink, orange, lime, green, indigo, purple }

class ColorStyleProvider with ChangeNotifier {
  static ColorStyle currentStyle = ColorStyle.green;

  static const pref_color = 'colorStyle';

  bool showPerformanceOverlay = false; // 是否在界面上显示性能调试层

  static final Map<ColorStyle, Map> styles = {
    ColorStyle.blue: {
      'mainColor': Colors.blue,
      'mainLightColor': Colors.blueAccent,
      'indicatorColor': Colors.blue,
    },
    ColorStyle.pink: {
      'mainColor': Colors.pink,
      'mainLightColor': Colors.pinkAccent,
      'indicatorColor': Colors.pink,
    },
    ColorStyle.orange: {
      'mainColor': Colors.deepOrange,
      'mainLightColor': Colors.deepOrangeAccent,
      'indicatorColor': Colors.orange,
    },
    ColorStyle.lime: {
      'mainColor': Colors.lightGreen,
      'mainLightColor': Colors.limeAccent,
      'indicatorColor': Colors.lime,
    },
    ColorStyle.green: {
      'mainColor': Colors.green,
      'mainLightColor': Colors.lightGreenAccent,
      'indicatorColor': Colors.orange,
    },
    ColorStyle.indigo: {
      'mainColor': Colors.indigo,
      'mainLightColor': Colors.indigoAccent,
      'indicatorColor': Colors.indigo,
    },
    ColorStyle.purple: {
      'mainColor': Colors.purple,
      'mainLightColor': Colors.purpleAccent,
      'indicatorColor': Colors.purple,
    },
  };

  Color getCurrentColor({String color = 'mainColor'}) {
    return getColor(currentStyle, color: color);
  }

  Color getLightColor() {
    return getColor(currentStyle, color: 'mainLightColor');
  }

  Color getIndicatorColor() {
    return getColor(currentStyle, color: 'indicatorColor');
  }

  Color getColor(ColorStyle style, {String color = 'mainColor'}) {
    Map? group = styles[style];
    return group?[color];
  }

  Future<void> setStyle(ColorStyle style) async {
    currentStyle = style;
    final prefs = await SharedPreferenceUtil.getInstance();
    prefs.setInt(pref_color, style.index);
    notifyListeners();
  }

  static Future<ColorStyle> initColorStyle() async {
    final SharedPreferences prefs = await SharedPreferenceUtil.getInstance();
    if (prefs.containsKey(pref_color)) {
      final int? styleIndex = prefs.getInt(pref_color);
      currentStyle = ColorStyle.values[styleIndex ?? 0];
    }
    return currentStyle;
  }

  setShowPerformanceOverlay(bool visible) {
    this.showPerformanceOverlay = visible;
    notifyListeners();
  }
}
