import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';

/// Thrown when [OneDriveGraphClient.downloadToFileStreaming] aborts early (stop / replaced batch).
class OneDriveDownloadCancelledException implements Exception {
  OneDriveDownloadCancelledException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'OneDriveDownloadCancelledException';
}

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
    final out = <OneDriveGraphItem>[];
    String? nextUrl = parentId == null
        ? '${OneDriveConfig.graphBase}/me/drive/root/children'
        : '${OneDriveConfig.graphBase}/me/drive/items/$parentId/children';
    while (nextUrl != null) {
      final res = await _getJson(nextUrl, accessToken);
      final list = res['value'] as List<dynamic>?;
      if (list != null) {
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            final item = OneDriveGraphItem.fromJson(e);
            if (item != null) {
              out.add(item);
            }
          }
        }
      }
      nextUrl = res['@odata.nextLink'] as String?;
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
    await downloadToFileStreaming(
      downloadUrl: downloadUrl,
      itemId: itemId,
      accessToken: accessToken,
      file: file,
      onProgress: (int received, int? total) {},
      waitWhilePaused: () async {},
      isCancelled: () => false,
    );
  }

  /// 流式写入并上报进度；支持暂停（轮询间阻塞）、取消（抛出 [OneDriveDownloadCancelledException]）。
  ///
  /// [file] 为最终路径；下载过程中先写入应用私有目录下的 `.part` 临时文件，完成后复制/移动到 [file]。
  Future<void> downloadToFileStreaming({
    String? downloadUrl,
    required String itemId,
    required String accessToken,
    required File file,
    required void Function(int received, int? total) onProgress,
    required Future<void> Function() waitWhilePaused,
    required bool Function() isCancelled,
  }) async {
    await file.parent.create(recursive: true);
    // Partial writes live under app-private storage so pause/resume does not rely on
    // reopen-append next to user-visible paths (Android scoped storage can EPERM).
    final support = await getApplicationSupportDirectory();
    final partsRoot = Directory(p.join(support.path, 'onedrive_download_parts'));
    await partsRoot.create(recursive: true);
    final key =
        '${file.path.hashCode.abs().toRadixString(16)}_${p.basename(file.path)}';
    final part = File(p.join(partsRoot.path, '$key.part'));

    Future<void> pump() async {
      await waitWhilePaused();
      if (isCancelled()) {
        throw OneDriveDownloadCancelledException();
      }
    }

    Future<void> streamInto({
      required Uri uri,
      required Map<String, String> headers,
    }) async {
      var existing = 0;
      if (await part.exists()) {
        existing = await part.length();
      }

      Future<void> writeFromScratch() async {
        if (await part.exists()) {
          await part.delete();
        }
        existing = 0;
      }

      Future<http.StreamedResponse> sendOnce({
        required bool useRange,
      }) async {
        final req = http.Request('GET', uri);
        req.headers.addAll(headers);
        if (useRange && existing > 0) {
          req.headers['Range'] = 'bytes=$existing-';
        }
        final streamed = await _client.send(req);
        return streamed;
      }

      var streamed = await sendOnce(useRange: existing > 0);

      // Range 不被接受时退回从头下载
      if (existing > 0 &&
          streamed.statusCode != 206 &&
          streamed.statusCode >= 200 &&
          streamed.statusCode < 300) {
        await streamed.stream.drain<void>();
        await writeFromScratch();
        streamed = await sendOnce(useRange: false);
      }

      // 416：本地偏移无效，清空重来一次
      if (streamed.statusCode == 416) {
        await streamed.stream.drain<void>();
        await writeFromScratch();
        streamed = await sendOnce(useRange: false);
      }

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        await streamed.stream.drain<void>();
        throw OneDriveApiException('GET ${uri.path} → ${streamed.statusCode}');
      }

      final totalBytes = _inferTotalBytes(streamed, existing);

      IOSink sink;
      if (existing <= 0 || streamed.statusCode == 200) {
        sink = part.openWrite();
      } else {
        sink = part.openWrite(mode: FileMode.append);
      }

      var receivedTotal = streamed.statusCode == 206 ? existing : 0;
      try {
        await for (final chunk in streamed.stream) {
          await pump();
          sink.add(chunk);
          receivedTotal += chunk.length;
          onProgress(receivedTotal, totalBytes);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    }

    try {
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        await streamInto(uri: Uri.parse(downloadUrl), headers: {});
      } else {
        final u = Uri.parse('${OneDriveConfig.graphBase}/me/drive/items/$itemId/content');
        await streamInto(
          uri: u,
          headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
        );
      }

      await pump();

      await _finalizePartToTarget(part: part, target: file);
    } on OneDriveDownloadCancelledException {
      rethrow;
    } catch (e) {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      rethrow;
    }
  }

  static Future<void> _finalizePartToTarget({
    required File part,
    required File target,
  }) async {
    if (!await part.exists()) {
      throw OneDriveApiException('missing temp download (.part)');
    }
    if (await target.exists()) {
      await target.delete();
    }
    try {
      await part.rename(target.path);
    } catch (_) {
      await part.copy(target.path);
      try {
        await part.delete();
      } catch (_) {}
    }
  }

  static int? _inferTotalBytes(http.StreamedResponse streamed, int resumeOffset) {
    final cr = streamed.headers['content-range'];
    if (cr != null && cr.isNotEmpty) {
      final m = RegExp(r'bytes\s+\d+-\d+/(\d+)').firstMatch(cr);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    final cl = streamed.headers['content-length'];
    final n = cl != null ? int.tryParse(cl) : null;
    if (n == null) return null;
    if (streamed.statusCode == 206) return resumeOffset + n;
    return n;
  }
}

class OneDriveApiException implements Exception {
  OneDriveApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
