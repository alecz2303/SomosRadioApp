class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.slug,
    required this.streamUrl,
    required this.isActive,
    required this.metadata,
  });

  final int? id;
  final String name;
  final String slug;
  final String streamUrl;
  final bool isActive;
  final Map<String, dynamic> metadata;

  String get frequency => metadata['frequency']?.toString() ?? name;
  String get city => metadata['city']?.toString() ?? '';

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as int?,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
