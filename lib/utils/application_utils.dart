import 'package:flutter/material.dart';
import 'package:yeah_music/config/app_config.dart';

class ApplicationUtils {
  ///弹出软件的“关于信息”
  static void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("关于"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 内容自适应，不撑满屏幕
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            children: const [
              Text("当前版本：v1.0.0"),
              SizedBox(height: 8), // 间距
              Text("作者：PengWeiZhong"),
              SizedBox(height: 8),
              Text("仓库地址："),
              // 可以复制文本
              SelectableText("https://github.com/pengweizhong/yeah_music", style: TextStyle(color: Colors.blue)),
              SizedBox(height: 8),
              Text("许可证：${AppConfig.copyright}"),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("关闭"))],
        );
      },
    );
  }

  ///自定义提示框
  static void alertDialog(BuildContext context, String title, List<Widget> children, List<TextButton> textButtons) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 内容自适应，不撑满屏幕
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            children: children, //弹出内容
          ),
          actions: textButtons,
        );
      },
    );
  }
}
