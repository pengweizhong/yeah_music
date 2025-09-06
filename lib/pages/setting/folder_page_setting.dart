import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/utils/application_utils.dart';

import '../../compments/folder_provider.dart';
import '../../models/folder.dart';
import '../../utils/date_utils.dart';

var log = Logger(printer: SimplePrinter());

class FolderPageSettings extends StatelessWidget {
  const FolderPageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    log.d("文件夹资源是否已经初始化？${folderProvider.initialized}");
    if (!folderProvider.initialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text("文件夹")),
      body: ListView.builder(
        itemCount: folderProvider.folders.length,
        itemBuilder: (context, index) {
          final folder = folderProvider.folders[index];
          return ListTile(
            title: Text(folder.name ?? "未知"),
            subtitle: Text("${folder.songList?.length} 首歌"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline_rounded),
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
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showRenameDialog(context, folder, folderProvider);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    folderProvider.deleteFolder(folder);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _showAddFolderDialog(context, folderProvider);
        },
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, FolderProvider provider) async {
    // 打开系统文件夹选择器
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      // 这里可以从路径自动获取文件夹名称，也可以自己输入名称
      bool isSuccess = await provider.addFolder(selectedDirectory);
      if (!isSuccess) {
        ApplicationUtils.alertDialog(context, "提示", "我知道了", [Text("添加了重复的文件夹：$selectedDirectory")]);
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
