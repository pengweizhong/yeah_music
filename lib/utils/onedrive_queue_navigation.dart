import 'package:flutter/material.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';

void openOneDriveTransferQueue({
  OneDriveTransferQueueTab initialTab = OneDriveTransferQueueTab.download,
}) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => OneDriveDownloadQueuePage(initialTab: initialTab),
    ),
  );
}
