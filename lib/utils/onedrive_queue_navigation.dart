// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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
