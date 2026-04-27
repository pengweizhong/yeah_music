import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yeah_music/config/onedrive_config.dart';

class OneDriveGraphItem {
  OneDriveGraphItem({
    required this.id,
    required this.name,
    required this.isFolder,
    this.downloadUrl,
  });

  final String id;
  final String name;
  final bool isFolder;
  final String? downloadUrl;

  static OneDriveGraphItem? fromJson(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    final name = m['name'] as String?;
    if (id == null || name == null) return null;
    final isFolder = m['folder'] != null;
    final dl = m['@microsoft.graph.downloadUrl'] as String?;
    return OneDriveGraphItem(
      id: id,
      name: name,
      isFolder: isFolder,
      downloadUrl: dl,
    );
  }
}

class OneDriveGraphClient {
  OneDriveGraphClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  void close() {
    _client.close();
  }

  /// [parentId] 为 `null` 时列出网盘根目录内容。
  Future<List<OneDriveGraphItem>> listChildren({
    required String accessToken,
    String? parentId,
  }) async {
    final path = parentId == null
        ? '${OneDriveConfig.graphBase}/me/drive/root/children'
        : '${OneDriveConfig.graphBase}/me/drive/items/$parentId/children';
    final res = await _getJson(path, accessToken);
    final list = res['value'] as List<dynamic>?;
    if (list == null) return const [];
    final out = <OneDriveGraphItem>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        final item = OneDriveGraphItem.fromJson(e);
        if (item != null) {
          out.add(item);
        }
      }
    }
    out.sort((a, b) {
      if (a.isFolder != b.isFolder) {
        return a.isFolder ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  /// 获取单文件元数据（含有时效下载链接）。
  Future<OneDriveGraphItem?> getItem({
    required String accessToken,
    required String itemId,
  }) async {
    final u = Uri(
      scheme: 'https',
      host: 'graph.microsoft.com',
      path: '/v1.0/me/drive/items/$itemId',
      query: r'$select=id,name,folder,file,@microsoft.graph.downloadUrl',
    );
    final res = await _getJson(u.toString(), accessToken);
    return OneDriveGraphItem.fromJson(res);
  }

  Future<Map<String, dynamic>> _getJson(String url, String accessToken) async {
    final u = Uri.parse(url);
    final r = await _client.get(
      u,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw OneDriveApiException('GET $url → ${r.statusCode}: ${r.body}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  /// 将内容下载到 [file]；优先使用 [downloadUrl]（可匿名 GET），否则走 `/content`。
  Future<void> downloadToFile({
    String? downloadUrl,
    required String itemId,
    required String accessToken,
    required File file,
  }) async {
    await file.parent.create(recursive: true);
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      final r = await _client.get(Uri.parse(downloadUrl));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw OneDriveApiException('downloadUrl → ${r.statusCode}');
      }
      await file.writeAsBytes(r.bodyBytes);
      return;
    }
    final u = Uri.parse('${OneDriveConfig.graphBase}/me/drive/items/$itemId/content');
    final req = http.Request('GET', u);
    req.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    final streamed = await _client.send(req);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw OneDriveApiException('content → ${streamed.statusCode}');
    }
    final bytes = await streamed.stream.toBytes();
    await file.writeAsBytes(bytes);
  }
}

class OneDriveApiException implements Exception {
  OneDriveApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
