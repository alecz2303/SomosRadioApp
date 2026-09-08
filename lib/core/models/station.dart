import 'channel.dart';

class Station {
  const Station({
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.channels,
  });

  final String name;
  final String slug;
  final String logoUrl;
  final List<Channel> channels;

  factory Station.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channels'];
    final channels = rawChannels is List
        ? rawChannels
            .whereType<Map>()
            .map((item) => Channel.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <Channel>[];

    return Station(
      name: json['name']?.toString() ?? 'Somos Radio',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      channels: channels,
    );
  }
}
