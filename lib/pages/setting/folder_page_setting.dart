import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/utils/application_utils.dart';

import '../../compments/bookmark_service.dart';
import '../../compments/folder_provider.dart';
import '../../compments/play_list_provider.dart';
import '../../models/folder.dart';
import '../../utils/date_utils.dart';

var log = Logger(printer: SimplePrinter());

class FolderPageSettings extends StatelessWidget {
  const FolderPageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    // log.d("文件夹资源是否已经初始化？${folderProvider.initialized}");
    if (!folderProvider.initialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("文件夹", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: ListView.builder(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
          itemCount: folderProvider.folders.length,
          itemBuilder: (context, index) {
            final folder = folderProvider.folders[index];
            return ListTile(
              title: Text(folder.name ?? "未知", style: const TextStyle(color: Colors.white)),
              subtitle: Text("${folder.songList?.length} 首歌", style: TextStyle(color: Colors.white.withOpacity(0.6))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                    tooltip: "目录信息",
                    onPressed: () {
                      showModalBottomSheet(
                        isScrollControlled: true, // 允许全屏滚动
                        context: context,
                        builder: (context) {
                          return Container(
                            width: double.infinity, // 横向撑满
                            height: 300,
                            // width: 200,
                            padding: EdgeInsets.all(16),
                            child: Column(
                              //左对齐
                              crossAxisAlignment: CrossAxisAlignment.start,
                              //主轴方向仅占用子组件需要的最小空间
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text("文件夹别名：", style: TextStyle(fontWeight: FontWeight.w900)),
                                    Text("${folder.name}"),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text("文件夹路径：", style: TextStyle(fontWeight: FontWeight.w900)),
                                    Flexible(
                                      child: SelectableText(
                                        folder.path,
                                        maxLines: null,
                                        showCursor: true,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text("歌曲数量：", style: TextStyle(fontWeight: FontWeight.w900)),
                                    Text("${folder.songList?.length}"),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text("加入时间：", style: TextStyle(fontWeight: FontWeight.w900)),
                                    Text(LocalDateUtils.formatDateTime(folder.createdAt, 'yyyy-MM-dd HH:mm:ss')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                    tooltip: "重新加载歌曲",
                    onPressed: () async {
                      // 显示加载进度对话框
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => WillPopScope(
                          onWillPop: () async => false,
                          child: AlertDialog(
                            title: Text("正在重新加载"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [CircularProgressIndicator(), SizedBox(height: 16), Text("正在扫描文件夹，请稍候...")],
                            ),
                          ),
                        ),
                      );

                      try {
                        await folderProvider.flushSongToFolder(folder, true);
                        context.read<PlayListProvider>().flushPlaylist(folder);

                        // 关闭进度对话框
                        Navigator.of(context).pop();

                        // 显示成功提示
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("成功加载 ${folder.songList?.length ?? 0} 首歌曲"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        // 关闭进度对话框
                        Navigator.of(context).pop();

                        // 显示错误提示
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("加载失败：$e"), duration: Duration(seconds: 3)));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: "编辑",
                    onPressed: () {
                      _showRenameDialog(context, folder, folderProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    tooltip: "移除目录",
                    onPressed: () {
                      ApplicationUtils.alertDialog(
                        context,
                        "确认移除？",
                        [Text("是否移除目录：${folder.name}")],
                        [
                          TextButton(
                            onPressed: () => {
                              //通知歌单更新
                              context.read<PlayListProvider>().flushRemovePlaylist(folder),
                              folderProvider.deleteFolder(folder),
                              Navigator.pop(context),
                            },
                            child: const Text("确认", style: TextStyle(color: Colors.red)),
                          ),
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
            ),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                _showAddFolderDialog(context, folderProvider);
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddFolderDialog(BuildContext context, FolderProvider provider) async {
    // 打开系统文件夹选择器
    String? selectedDirectory;
    if (Platform.isMacOS) {
      selectedDirectory = await BookmarkService.pickDirectory();
    } else {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    }
    if (selectedDirectory != null) {
      // 显示加载进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text("正在加载歌曲"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text("正在扫描文件夹，请稍候...")],
            ),
          ),
        ),
      );

      try {
        // 这里可以从路径自动获取文件夹名称，也可以自己输入名称
        Folder? addFolder = await provider.addFolder(selectedDirectory);

        // 关闭进度对话框
        Navigator.of(context).pop();

        if (addFolder == null) {
          ApplicationUtils.alertDialog(
            context,
            "提示",
            [Text("添加了重复的文件夹：$selectedDirectory")],
            [TextButton(onPressed: () => Navigator.pop(context), child: const Text("我知道了"))],
          );
        } else {
          //通知歌单更新
          final playListProvider = context.read<PlayListProvider>();
          playListProvider.flushAddPlaylist(addFolder);

          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("成功添加 ${addFolder.songList?.length ?? 0} 首歌曲"), duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        // 关闭进度对话框
        Navigator.of(context).pop();

        // 显示错误提示
        ApplicationUtils.alertDialog(
          context,
          "错误",
          [Text("加载文件夹失败：$e")],
          [TextButton(onPressed: () => Navigator.pop(context), child: const Text("确定"))],
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context, Folder folder, FolderProvider provider) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("重命名文件夹"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "新名称"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("取消")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameFolder(folder, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text("确定"),
          ),
        ],
      ),
    );
  }
}
