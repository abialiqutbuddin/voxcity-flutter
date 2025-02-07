import 'package:flutter/material.dart';
import '../../api/api.dart';
import '../../models/drive_model.dart';

class DirectoryPage extends StatefulWidget {
  final String folderId;
  final String folderName;
  final String bookingCode;

  const DirectoryPage({super.key, required this.folderId, required this.folderName, required this.bookingCode});

  @override
  DirectoryPageState createState() => DirectoryPageState();
}

class DirectoryPageState extends State<DirectoryPage> {
  late String currentFolderId;
  late String currentFolderName;
  late Future<List<DriveItem>> _folderContents;
  DriveItem? _selectedFile; // Track selected file
  bool _isFileSelected = false; // Track if file is selected for upload
  DriveItem? _hoveredFile; // Track the hovered file

  @override
  void initState() {
    super.initState();
    currentFolderId = widget.folderId;
    currentFolderName = widget.folderName;
    _folderContents = Wave.getFolderContents(currentFolderId);
  }

  void _updateFolder(String folderId, String folderName) {
    setState(() {
      currentFolderId = folderId;
      currentFolderName = folderName;
      _folderContents = Wave.getFolderContents(folderId);
    });
  }

  void _handlePopResult(bool didPop, bool? result) {
    if (didPop) {
      // Handle successful pop
    } else {
      // Handle failed or canceled pop
    }
  }

  // Handle file tap
  void _onFileSelected(DriveItem file) {
    setState(() {
      _selectedFile = file;
      _isFileSelected = true; // Mark that a file has been selected
    });
  }

  // Upload file method
  void _uploadFile() async {
    if (_selectedFile == null) {
      // Debug: Check if no file is selected
      return; // Check if no file is selected
    }

    try {
      // Debug: Output selected file details

      // Get file bytes using the Wave API
      final filePath = await Wave.getFilePath(_selectedFile!.id);

      // Send the file to the backend
      await Wave.sendFileToBackend(filePath,widget.bookingCode);

      // Debug: File upload success

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!'))
      );
    } catch (e) {
      // Debug: Handle errors and print the exception message

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file hehehe: $e'))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: currentFolderId != '1lvelAgggBucbgMMJu9Zpd8baRZrQWvtP', // Prevent pop in root folder
      onPopInvokedWithResult: (bool didPop, bool? result) {
        _handlePopResult(didPop, result); // Handle pop result
      },
      child: Material(
        child: Column(
          children: [
            AppBar(
              title: Text(currentFolderName),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: Navigator.of(context).maybePop,
              ),
            ),
            if (_isFileSelected)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _uploadFile,
                  child: const Text('Upload Selected File'),
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
                        final isFolder = item.mimeType ==
                            'application/vnd.google-apps.folder';

                        final isSelected = _selectedFile == item;
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
                              _onFileSelected(item);
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
      ),
    );
  }
}
