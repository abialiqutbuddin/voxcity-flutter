class DriveItem {
  final String id;
  final String name;
  final String mimeType;

  DriveItem({required this.id, required this.name, required this.mimeType});

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      id: json['id'],
      name: json['name'],
      mimeType: json['mimeType'],
    );
  }
}
