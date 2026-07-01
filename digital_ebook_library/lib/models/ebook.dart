class Ebook {
  final int id;
  final String title;
  final String? author;
  final String? fileType;
  final int? fileSize;
  final String? fileName;
  final DateTime createdAt;
  final String? coverUrl;
  final String? downloadUrl;

  Ebook({
    required this.id,
    required this.title,
    this.author,
    this.fileType,
    this.fileSize,
    this.fileName,
    required this.createdAt,
    this.coverUrl,
    this.downloadUrl,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      author: json['author'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      fileName: json['file_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      coverUrl: json['cover_url'],
      downloadUrl: json['download_url'],
    );
  }

  String get fileSizeLabel {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  bool get isPdf => (fileType ?? '').contains('pdf');
}
