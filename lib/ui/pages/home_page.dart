import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/audio_service.dart';
import '../widgets/player_controls.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final _service = AudioService();

  Future<void> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await _service.loadSongs(path);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appTitle),
        actions: [
          IconButton(
            onPressed: pickFolder,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _service.songs.length,
              itemBuilder: (context, index) {
                final name = _service.songs[index].uri.pathSegments.last;
                return ListTile(
                  title: Text(name),
                  selected: index == _service.currentIndex,
                  onTap: () async {
                    await _service.playSong(index);
                    setState(() {});
                  },
                );
              },
            ),
          ),
          PlayerControls(service: _service),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
