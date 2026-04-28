import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/utils/cloud_track_list_utils.dart';

/// 云端曲库内搜索：匹配文件名或 [OneDriveCloudTrack.displayPath]。
class CloudTrackSearchDelegate extends SearchDelegate<OneDriveCloudTrack?> {
  CloudTrackSearchDelegate({
    required this.sortedTracks,
    required this.searchFieldLabelText,
  }) : super(
          searchFieldStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        );

  final List<OneDriveCloudTrack> sortedTracks;
  final String searchFieldLabelText;

  @override
  String get searchFieldLabel => searchFieldLabelText;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        toolbarTextStyle: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
      ),
    );
  }

  @override
  Widget? buildFlexibleSpace(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: const SizedBox.expand(),
        );
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _body(context);

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: _list(context),
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = filterCloudTracksByQuery(sortedTracks, query);
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.white.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoMatchingSongs,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (context, index) {
        final t = filtered[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.audiotrack_rounded, color: Color(0xFF81D4FA), size: 22),
          title: Text(
            t.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            t.displayPath,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => close(context, t),
        );
      },
    );
  }
}
