class ProjectModel {
  final String path;
  final String title;
  final DateTime createdAt;
  final int sizeBytes;
  final int durationSeconds;

  ProjectModel({
    required this.path,
    required this.title,
    required this.createdAt,
    required this.sizeBytes,
    required this.durationSeconds,
  });

  String get formattedSize {
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final d = Duration(seconds: durationSeconds);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:${s}s';
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'durationSeconds': durationSeconds,
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        path: json['path'] as String,
        title: json['title'] as String? ?? 'Untitled',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );
}
