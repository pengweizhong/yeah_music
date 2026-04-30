import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yeah_music/config/app_product_info.dart';

/// [GitHub Releases — Latest](https://docs.github.com/en/rest/releases/releases#get-the-latest-release)
sealed class GithubUpdateCheckOutcome {
  const GithubUpdateCheckOutcome();
}

/// 远程语义版本不高于当前安装版本。
final class GithubUpdateCheckUpToDate extends GithubUpdateCheckOutcome {
  const GithubUpdateCheckUpToDate();
}

final class GithubUpdateCheckNewVersion extends GithubUpdateCheckOutcome {
  const GithubUpdateCheckNewVersion({
    required this.latestVersion,
    required this.releasePageUrl,
  });

  /// 规范化后的 `x.y.z`（来自 release tag）。
  final String latestVersion;

  /// `html_url`，一般为该 Release 页面。
  final String releasePageUrl;
}

final class GithubUpdateCheckFailure extends GithubUpdateCheckOutcome {
  const GithubUpdateCheckFailure(this.reasonCode);

  /// 内部原因码；UI 映射为本地化短句。
  final String reasonCode;
}

abstract final class GithubReleaseUpdateChecker {
  GithubReleaseUpdateChecker._();

  static const String owner = 'pengweizhong';
  static const String repo = 'yeah_music';

  /// 请求 GitHub latest release，将 [tag_name] 与 [AppProductInfo.version] 比较（均规范到 `x.y.z`）。
  static Future<GithubUpdateCheckOutcome> checkAgainstLatestRelease() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases/latest',
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent':
                '${AppProductInfo.displayName}/${AppProductInfo.version}',
          },
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode == 404) {
      return const GithubUpdateCheckFailure('no_release');
    }
    if (response.statusCode != 200) {
      return GithubUpdateCheckFailure('http_${response.statusCode}');
    }

    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const GithubUpdateCheckFailure('bad_json');
      }
      json = decoded;
    } catch (_) {
      return const GithubUpdateCheckFailure('bad_json');
    }

    final tag = json['tag_name'];
    final htmlUrl = json['html_url'];
    if (tag is! String || htmlUrl is! String || htmlUrl.isEmpty) {
      return const GithubUpdateCheckFailure('bad_payload');
    }

    final remoteVer = normalizeReleaseTagToSemver(tag);
    final localVer = normalizeReleaseTagToSemver(AppProductInfo.version);
    if (compareSemver(remoteVer, localVer) <= 0) {
      return const GithubUpdateCheckUpToDate();
    }
    return GithubUpdateCheckNewVersion(
      latestVersion: remoteVer,
      releasePageUrl: htmlUrl,
    );
  }

  /// `v1.2.3` / `1.2.3-beta` → `1.2.3`（无法解析时为 `0.0.0`）。
  static String normalizeReleaseTagToSemver(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(s);
    if (m != null) {
      return '${m[1]}.${m[2]}.${m[3]}';
    }
    final nums = RegExp(r'\d+').allMatches(s).map((e) => e.group(0)!).toList();
    if (nums.isEmpty) return '0.0.0';
    final a = nums.isNotEmpty ? int.tryParse(nums[0]) ?? 0 : 0;
    final b = nums.length > 1 ? int.tryParse(nums[1]) ?? 0 : 0;
    final c = nums.length > 2 ? int.tryParse(nums[2]) ?? 0 : 0;
    return '$a.$b.$c';
  }

  /// &gt;0 ： [a] 新于 [b]；0 相等；&lt;0 [a] 旧于 [b]。
  static int compareSemver(String a, String b) {
    List<int> parts(String v) {
      final segs = v.split('.');
      final out = <int>[];
      for (final seg in segs) {
        final n = int.tryParse(seg.trim());
        if (n == null) break;
        out.add(n);
      }
      while (out.length < 3) {
        out.add(0);
      }
      return out.take(3).toList();
    }

    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final c = pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return 0;
  }
}
