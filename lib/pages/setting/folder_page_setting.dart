import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/utils/application_utils.dart';

import '../../compments/bookmark_service.dart';
import '../../compments/frosted_glass_panel.dart';
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
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        showDragHandle: false,
                        context: context,
                        builder: (sheetContext) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                            ),
                            child: FrostedGlassBottomSheet(
                              child: Theme(
                                data: frostedBottomSheetContentTheme(sheetContext),
                                child: SafeArea(
                                  top: false,
                                  child: SizedBox(
                                    height: 300,
                                    width: double.infinity,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                      child: DefaultTextStyle(
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '目录信息',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '文件夹别名：',
                                                  style: TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                                Expanded(child: Text('${folder.name}')),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '文件夹路径：',
                                                  style: TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                                Expanded(
                                                  child: SelectableText(
                                                    folder.path,
                                                    maxLines: null,
                                                    showCursor: true,
                                                    textAlign: TextAlign.start,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text(
                                                  '歌曲数量：',
                                                  style: TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                                Text('${folder.songList?.length}'),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text(
                                                  '加入时间：',
                                                  style: TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                                Text(
                                                  LocalDateUtils.formatDateTime(
                                                    folder.createdAt,
                                                    'yyyy-MM-dd HH:mm:ss',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                      showFrostedDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        child: PopScope(
                          canPop: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '正在重新加载',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  '正在扫描文件夹，请稍候…',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, height: 1.3),
                                ),
                              ],
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
      showFrostedDialog<void>(
        context: context,
        barrierDismissible: false,
        child: PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '正在加载歌曲',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '正在扫描文件夹，请稍候…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, height: 1.3),
                ),
              ],
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
    showFrostedDialog<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '重命名文件夹',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: '新名称',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          provider.renameFolder(folder, controller.text.trim());
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
