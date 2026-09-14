class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.placement,
    this.advertiser,
    this.targetUrl,
  });

  final int id;
  final String name;
  final String imageUrl;
  final String placement;
  final String? advertiser;
  final String? targetUrl;

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Publicidad',
      advertiser: _nullableString(json['advertiser']),
      imageUrl: json['image_url']?.toString() ?? '',
      targetUrl: _nullableString(json['target_url']),
      placement: json['placement']?.toString() ?? 'home',
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
