import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FileTransferView extends StatefulWidget {
  const FileTransferView({Key? key}) : super(key: key);

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView> {
  final List<String> _files = [
    "📄 SystemLog_2026.log (1.2 MB)",
    "🖼️ Screenshot_Capture.png (3.4 MB)",
    "📦 Backup_Archive.tar.gz (45.8 MB)",
    "📊 Financial_Report.pdf (890 KB)"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mobile File Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            tooltip: "Upload Photo",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Photo gallery upload triggered")),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppTheme.accent),
              title: Text(_files[index], style: const TextStyle(color: AppTheme.textPrimary)),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: AppTheme.success),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Downloading ${_files[index]}...")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
