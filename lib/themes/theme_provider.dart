import 'package:flutter/material.dart';
import 'package:yeah_music/themes/dark_model.dart';
import 'package:yeah_music/themes/light_model.dart';

class ThemeProvider extends ChangeNotifier {
  //默认模式
  ThemeData _themeData = lightTheme;

  ThemeData get themeData => _themeData;

  bool get isDarkTheme => _themeData == darkTheme;

  set themeData(ThemeData t) {
    _themeData = t;
    //设置主题后更新UI
    notifyListeners();
  }

  ///切换主题
  void toggleTheme() {
    if (_themeData == lightTheme) {
      //编译器实际上会调用这个 setter 方法，效果等价于
      //this.setThemeData(darkTheme);
      themeData = darkTheme;
    } else {
      themeData = lightTheme;
    }
  }
}
