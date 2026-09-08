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

  String get frequency {
    final value = metadata['frequency']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;

    switch (slug) {
      case 'somos-radio-89-1':
        return '89.1 FM';
      case 'somos-radio-102-9':
        return '102.9 FM';
      default:
        return name;
    }
  }

  String get city {
    final value = metadata['city']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;

    switch (slug) {
      case 'somos-radio-89-1':
        return 'Tuxtla Gutiérrez';
      case 'somos-radio-102-9':
        return 'San Cristóbal de las Casas';
      default:
        return '';
    }
  }

  String get callsign {
    final value = metadata['callsign']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;

    switch (slug) {
      case 'somos-radio-89-1':
        return 'XHITG';
      case 'somos-radio-102-9':
        return 'XHSCC';
      default:
        return '';
    }
  }

  String get displayName {
    final value = frequency;
    return value.toLowerCase().startsWith('somos radio')
        ? value
        : 'Somos Radio $value';
  }

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
