import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/channel.dart';

class RadioApiClient {
  RadioApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Channel>> fetchSomosRadioChannels() async {
    if (AppConfig.radioApiBaseUrl.isEmpty) {
      return _demoChannels;
    }

    final uri = Uri.parse(
      '${AppConfig.radioApiBaseUrl}/stations/${AppConfig.stationSlug}/channels',
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException('La API respondió ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final items = _extractList(decoded);

    return items
        .whereType<Map>()
        .map((item) => Channel.fromJson(item.cast<String, dynamic>()))
        .where((channel) => channel.isActive)
        .toList();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
      final channels = decoded['channels'];
      if (channels is List) return channels;
    }
    throw const RadioApiException('Formato inesperado en la respuesta de la API.');
  }

  static const _demoChannels = <Channel>[
    Channel(
      id: null,
      name: '89.1 FM',
      slug: '89-1-tuxtla',
      streamUrl: '',
      isActive: true,
      metadata: {
        'frequency': '89.1 FM',
        'city': 'Tuxtla Gutiérrez',
      },
    ),
    Channel(
      id: null,
      name: '102.9 FM',
      slug: '102-9-san-cristobal',
      streamUrl: '',
      isActive: true,
      metadata: {
        'frequency': '102.9 FM',
        'city': 'San Cristóbal de las Casas',
      },
    ),
  ];
}

class RadioApiException implements Exception {
  const RadioApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
