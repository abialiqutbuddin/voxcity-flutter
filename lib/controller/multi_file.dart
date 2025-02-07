import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/drive_model.dart';

class MultiDirectoryPage extends StatefulWidget {
  final String folderId;
  final String folderName;
  final List<Map<String, dynamic>> customers;

  const MultiDirectoryPage({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.customers,
  });

  @override
  MultiDirectoryPageState createState() => MultiDirectoryPageState();
}

class MultiDirectoryPageState extends State<MultiDirectoryPage> {
  late String currentFolderId;
  late String currentFolderName;
  late Future<List<DriveItem>> _folderContents;
  final Set<DriveItem> _selectedFiles = {}; // Track selected files
  late final customers;
  DriveItem? _hoveredFile; // Track the hovered file

  @override
  void initState() {
    super.initState();
    customers = widget.customers;
    currentFolderId = widget.folderId;
    currentFolderName = widget.folderName;

    _folderContents = Wave.getFolderContents(currentFolderId);
  }

  void _updateFolder(String folderId, String folderName) {
    setState(() {
      currentFolderId = folderId;
      currentFolderName = folderName;
      _folderContents = Wave.getFolderContents(folderId);
      _selectedFiles.clear(); // Clear selections when navigating folders
    });
  }

  void _toggleFileSelection(DriveItem file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  // Upload selected files
  void _uploadSelectedFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected for upload!')),
      );
      return;
    }

    List<String> fileIds = [];
    List<String> bookingIds = [];

    for(final file in _selectedFiles){
      fileIds.add(file.id);
    }

    for (final customer in customers) {
      if (customer.containsKey('bookingId')) {
        final cleanCode = customer['bookingId'].replaceAll('#', '');
        bookingIds.add(cleanCode);
      }
    }

    try {
      await Wave.sendFileIdsAndBookingCodes(fileIds,bookingIds);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected files uploaded successfully!')),
      );
      _selectedFiles.clear(); // Clear the selection after upload

      setState(() {}); // Refresh the UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          AppBar(
            title: Text(currentFolderName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: Navigator.of(context).maybePop,
            ),
          ),
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _uploadSelectedFiles,
                child: Text(
                  'Upload Selected Files (${_selectedFiles.length})',
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<DriveItem>>(
              future: _folderContents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No contents found.'));
                } else {
                  final items = snapshot.data!;
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isFolder = item.mimeType == 'application/vnd.google-apps.folder';

                      final isSelected = _selectedFiles.contains(item);
                      final isHovered = _hoveredFile == item;

                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _hoveredFile = item;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _hoveredFile = null;
                          });
                        },
                        child: ListTile(
                          leading: Icon(
                            isFolder
                                ? Icons.folder
                                : Icons.insert_drive_file,
                            color: isSelected
                                ? Colors.blue
                                : isHovered
                                ? Colors.blueAccent
                                : null,
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.blue
                                  : isHovered
                                  ? Colors.blueAccent
                                  : null,
                            ),
                          ),
                          tileColor: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : isHovered
                              ? Colors.blue.withOpacity(0.05)
                              : null,
                          onTap: isFolder
                              ? () {
                            _updateFolder(item.id, item.name);
                          }
                              : () {
                            _toggleFileSelection(item);
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}