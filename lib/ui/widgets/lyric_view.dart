import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/song.dart';

class LyricView extends StatelessWidget {
  final ValueNotifier<Song?> valueNotifierSong;

  const LyricView({super.key, required this.valueNotifierSong});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: valueNotifierSong,
      builder: (context, song, _) {
        return buildLyrics();
      },
    );
  }

  Widget buildLyrics() {
    String lyrics = valueNotifierSong.value?.lyrics ?? "暂无歌词";
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        lyrics,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.blue,
        showCursor: true,
        contextMenuBuilder: (context, editableTextState) {
          // 把默认的按钮项拿出来
          final defaultItems = editableTextState.contextMenuButtonItems.map((
            item,
          ) {
            if (item.type.name.toLowerCase() == 'copy') {
              // 把英文 Copy 改成 复制
              return ContextMenuButtonItem(
                label: '复制',
                onPressed: item.onPressed,
              );
            }
            return item;
          }).toList();
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: <ContextMenuButtonItem>[
              // ...editableTextState.contextMenuButtonItems,
              //加入已经变更的
              ...defaultItems,
              ContextMenuButtonItem(
                label: '复制整首歌词',
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: lyrics));
                    // 等待确认复制完成再关闭菜单
                    if (Navigator.canPop(context)) Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('歌词已复制到剪贴板')));
                  } catch (e, st) {
                    debugPrint('复制出错: $e\n$st');
                    if (Navigator.canPop(context)) Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('复制失败')));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
