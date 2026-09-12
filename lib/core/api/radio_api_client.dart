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
      '${AppConfig.radioApiBaseUrl}/stations/${AppConfig.stationSlug}',
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 404 && AppConfig.isConceptDemo) {
      return _demoChannels;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException('La API respondió ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final items = _extractChannels(decoded);

    return items
        .whereType<Map>()
        .map((item) => Channel.fromJson(item.cast<String, dynamic>()))
        .where((channel) => channel.isActive)
        .toList();
  }

  Future<SongRequestResult> submitSongRequest({
    required String channelSlug,
    required String listenerName,
    required String song,
    required String artist,
    String? dedication,
  }) async {
    if (AppConfig.radioApiBaseUrl.isEmpty) {
      throw const RadioApiException('La API no está configurada.');
    }

    final uri = Uri.parse('${AppConfig.radioApiBaseUrl}/song-requests');
    final response = await _client
        .post(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'station_slug': AppConfig.stationSlug,
            'channel_slug': channelSlug,
            'listener_name': listenerName.trim(),
            'song': song.trim(),
            'artist': artist.trim(),
            'dedication': dedication?.trim(),
          }),
        )
        .timeout(const Duration(seconds: 12));

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'No fue posible enviar la solicitud.';
      if (decoded is Map<String, dynamic>) {
        final apiMessage = decoded['message']?.toString().trim();
        if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
      throw RadioApiException(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const RadioApiException('Formato inesperado en la respuesta de la API.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw const RadioApiException('La API no devolvió la solicitud creada.');
    }

    final mapped = data.cast<String, dynamic>();
    return SongRequestResult(
      id: mapped['id'] as int?,
      status: mapped['status']?.toString() ?? 'new',
      station: mapped['station']?.toString() ?? 'Somos Radio',
      channel: mapped['channel']?.toString() ?? '',
      message: decoded['message']?.toString() ?? 'Solicitud recibida correctamente.',
    );
  }

  List<dynamic> _extractChannels(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final channels = decoded['channels'];
      if (channels is List) return channels;

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final nestedChannels = data['channels'];
        if (nestedChannels is List) return nestedChannels;
      }
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
        'source': 'demo',
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
        'source': 'demo',
      },
    ),
  ];
}

class SongRequestResult {
  const SongRequestResult({
    required this.id,
    required this.status,
    required this.station,
    required this.channel,
    required this.message,
  });

  final int? id;
  final String status;
  final String station;
  final String channel;
  final String message;
}

class RadioApiException implements Exception {
  const RadioApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
