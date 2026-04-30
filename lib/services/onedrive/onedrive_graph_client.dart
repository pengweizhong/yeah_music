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

  /// 读取云盘文件内容为 UTF-8 文本（小到中等 JSON）；优先匿名 [downloadUrl]，否则 Bearer GET `/content`。
  Future<String> downloadDriveItemUtf8({
    required String accessToken,
    required String itemId,
  }) async {
    final meta = await getItem(accessToken: accessToken, itemId: itemId);
    if (meta == null || meta.id.trim().isEmpty) {
      throw OneDriveApiException('item not found: $itemId');
    }
    final dl = meta.downloadUrl;
    Uri uri;
    Map<String, String> headers = const {};
    if (dl != null && dl.isNotEmpty) {
      uri = Uri.parse(dl);
    } else {
      uri = Uri.parse('${OneDriveConfig.graphBase}/me/drive/items/$itemId/content');
      headers = {HttpHeaders.authorizationHeader: 'Bearer $accessToken'};
    }
    final r = await _client.get(uri, headers: headers);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw OneDriveApiException(
        'GET content → ${r.statusCode}: ${r.body.length > 200 ? '${r.body.substring(0, 200)}…' : r.body}',
      );
    }
    return utf8.decode(r.bodyBytes);
  }

  /// 获取 drive item 的父文件夹 Graph id（用于与同目录下的封面文件配对）。
  Future<String?> driveItemParentFolderId({
    required String accessToken,
    required String itemId,
  }) async {
    final u = Uri(
      scheme: 'https',
      host: 'graph.microsoft.com',
      path: '/v1.0/me/drive/items/${itemId.trim()}',
      queryParameters: const {'\$select': 'parentReference'},
    );
    final decoded = await _getJson(u.toString(), accessToken);
    final pref = decoded['parentReference'];
    if (pref is! Map<String, dynamic>) return null;
    final pid = pref['id'];
    if (pid is String && pid.trim().isNotEmpty) return pid.trim();
    return null;
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

  static String _driveItemChildPathUrl(
    String parentItemId,
    String remoteFileName,
    String suffix,
  ) {
    final normalized =
        remoteFileName.replaceAll('\\', '/').split('/').where((e) => e.isNotEmpty).join('/');
    final encoded = normalized
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    return '${OneDriveConfig.graphBase}/me/drive/items/$parentItemId:/$encoded:/$suffix';
  }

  /// Graph 要求冲突策略作为查询参数；名称含 `@`，避免交给 [Uri] 编码导致 400/403。
  static Uri _uploadUriWithConflictReplace(String pathWithoutQuery) {
    final sep = pathWithoutQuery.contains('?') ? '&' : '?';
    return Uri.parse(
      '$pathWithoutQuery$sep@microsoft.graph.conflictBehavior=replace',
    );
  }

  /// 单文件上传（小文件一次 PUT；大于 4MiB 自动走上传会话分块）。行为与下载对称，支持暂停/取消。
  Future<void> uploadLocalFileWithProgress({
    required String accessToken,
    required String parentItemId,
    required String remoteFileName,
    required File file,
    required void Function(int sent, int total) onProgress,
    required Future<void> Function() waitWhilePaused,
    required bool Function() isCancelled,
  }) async {
    const simpleMax = 4 * 1024 * 1024;
    const chunkSize = 10 * 320 * 1024;

    Future<void> pump() async {
      await waitWhilePaused();
      if (isCancelled()) {
        throw OneDriveDownloadCancelledException();
      }
    }

    final len = await file.length();
    if (len <= 0) {
      throw OneDriveApiException('empty file');
    }

    if (len <= simpleMax) {
      await pump();
      final bytes = await file.readAsBytes();
      await pump();
      final url = _uploadUriWithConflictReplace(
        _driveItemChildPathUrl(parentItemId, remoteFileName, 'content'),
      );
      final put = await _client.put(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
        },
        body: bytes,
      );
      if (put.statusCode < 200 || put.statusCode >= 300) {
        throw OneDriveApiException('PUT upload → ${put.statusCode}: ${put.body}');
      }
      onProgress(len, len);
      return;
    }

    await pump();
    final sessionUrl = _uploadUriWithConflictReplace(
      _driveItemChildPathUrl(parentItemId, remoteFileName, 'createUploadSession'),
    );
    final create = await _client.post(
      sessionUrl,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: '{"item":{"@microsoft.graph.conflictBehavior":"replace"}}',
    );
    if (create.statusCode < 200 || create.statusCode >= 300) {
      throw OneDriveApiException(
        'createUploadSession → ${create.statusCode}: ${create.body}',
      );
    }
    final sessionMap = json.decode(create.body) as Map<String, dynamic>;
    final uploadUrl = sessionMap['uploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw OneDriveApiException('missing uploadUrl');
    }

    var offset = 0;
    final rs = await file.open();
    try {
      while (offset < len) {
        await pump();
        final end = (offset + chunkSize < len) ? offset + chunkSize : len;
        final chunkLen = end - offset;
        await rs.setPosition(offset);
        final chunk = await rs.read(chunkLen);
        if (chunk.length != chunkLen) {
          throw OneDriveApiException('short read');
        }
        final cr = 'bytes $offset-${end - 1}/$len';
        final putChunk = await _client.put(
          Uri.parse(uploadUrl),
          headers: {
            HttpHeaders.contentLengthHeader: '$chunkLen',
            'Content-Range': cr,
          },
          body: chunk,
        );
        if (putChunk.statusCode != 200 &&
            putChunk.statusCode != 201 &&
            putChunk.statusCode != 202) {
          throw OneDriveApiException(
            'chunk upload → ${putChunk.statusCode}: ${putChunk.body}',
          );
        }
        offset = end;
        onProgress(offset, len);
      }
    } finally {
      await rs.close();
    }
  }

  /// 在 [parentId] 为 `null` 时在「我的文件」根下查找同名文件夹（不含文件）。
  Future<OneDriveGraphItem?> findChildFolderNamed({
    required String accessToken,
    String? parentId,
    required String folderName,
  }) async {
    final want = folderName.trim().toLowerCase();
    if (want.isEmpty) return null;
    final kids = await listChildren(accessToken: accessToken, parentId: parentId);
    for (final c in kids) {
      if (c.isFolder && c.name.trim().toLowerCase() == want) {
        return c;
      }
    }
    return null;
  }

  /// 在指定父文件夹下新建子文件夹；[parentId] 为 `null` 时创建于云盘根「我的文件」。
  Future<OneDriveGraphItem?> createFolderChild({
    required String accessToken,
    String? parentId,
    required String folderName,
  }) async {
    final name = folderName.trim();
    if (name.isEmpty) return null;
    final url = parentId == null || parentId.trim().isEmpty
        ? '${OneDriveConfig.graphBase}/me/drive/root/children'
        : '${OneDriveConfig.graphBase}/me/drive/items/${parentId.trim()}/children';
    final body = json.encode(<String, dynamic>{
      'name': name,
      'folder': <String, dynamic>{},
      '@microsoft.graph.conflictBehavior': 'rename',
    });
    final r = await _client.post(
      Uri.parse(url),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: body,
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw OneDriveApiException('POST folder → ${r.statusCode}: ${r.body}');
    }
    final decoded = json.decode(r.body) as Map<String, dynamic>;
    return OneDriveGraphItem.fromJson(decoded);
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
        onProgress(receivedTotal, totalBytes);
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
