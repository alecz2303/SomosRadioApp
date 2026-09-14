import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/channel.dart';

class RadioStationCatalog {
  const RadioStationCatalog._();

  static const channels = <Channel>[
    Channel(
      id: 3,
      name: 'Somos Radio 89.1 FM',
      slug: 'somos-radio-89-1',
      streamUrl: 'https://stream.freepi.io/8332/live',
      isActive: true,
      metadata: {
        'frequency': '89.1 FM',
        'city': 'Tuxtla Gutiérrez',
        'callsign': 'XHITG',
      },
    ),
    Channel(
      id: 4,
      name: 'Somos Radio 102.9 FM',
      slug: 'somos-radio-102-9',
      streamUrl: 'https://stream.freepi.io/8334/live',
      isActive: true,
      metadata: {
        'frequency': '102.9 FM',
        'city': 'San Cristóbal de las Casas',
        'callsign': 'XHSCC',
      },
    ),
  ];

  static Channel? bySlug(String slug) {
    for (final channel in channels) {
      if (channel.slug == slug) return channel;
    }
    return null;
  }

  static Uri? artworkUri(String slug) {
    switch (slug) {
      case 'somos-radio-89-1':
        return Uri.parse(
          'https://raw.githubusercontent.com/alecz2303/SomosRadioApp/main/assets/stations/somos_89_1.webp',
        );
      case 'somos-radio-102-9':
        return Uri.parse(
          'https://raw.githubusercontent.com/alecz2303/SomosRadioApp/main/assets/stations/somos_102_9.webp',
        );
      default:
        return null;
    }
  }
}

class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        _scheduleReconnect();
      },
    );

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _shouldBePlaying) {
        _scheduleReconnect();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Channel? _currentChannel;
  Timer? _reconnectTimer;
  bool _shouldBePlaying = false;
  bool _reconnecting = false;
  int _reconnectAttempt = 0;

  Future<void> _playChannel(Channel channel) async {
    if (channel.streamUrl.trim().isEmpty) {
      customEvent.add({
        'type': 'error',
        'message': 'Esta estación todavía no tiene un stream publicado.',
      });
      return;
    }

    _reconnectTimer?.cancel();
    _currentChannel = channel;
    _shouldBePlaying = true;
    _reconnectAttempt = 0;

    final item = MediaItem(
      id: channel.slug,
      album: 'Somos Radio Chiapas',
      title: channel.displayName,
      artist: channel.city.isNotEmpty ? channel.city : 'Chiapas',
      displayTitle: channel.displayName,
      displaySubtitle: channel.city.isNotEmpty ? channel.city : 'Chiapas',
      displayDescription: 'En vivo',
      artUri: RadioStationCatalog.artworkUri(channel.slug),
      isLive: true,
      extras: {
        'channel_id': channel.id,
        'name': channel.name,
        'slug': channel.slug,
        'stream_url': channel.streamUrl,
        'is_active': channel.isActive,
        'frequency': channel.frequency,
        'city': channel.city,
        'callsign': channel.callsign,
      },
    );

    mediaItem.add(item);

    try {
      await _player.stop();
      await _player.setUrl(channel.streamUrl);
      if (_shouldBePlaying && _currentChannel?.slug == channel.slug) {
        await _player.play();
      }
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldBePlaying || _currentChannel == null || _reconnecting) return;
    if (_reconnectTimer?.isActive ?? false) return;

    final delays = <int>[2, 4, 8, 12, 20];
    final index = _reconnectAttempt.clamp(0, delays.length - 1);
    final delay = Duration(seconds: delays[index]);
    _reconnectAttempt++;

    _reconnectTimer = Timer(delay, _reconnect);
  }

  Future<void> _reconnect() async {
    final channel = _currentChannel;
    if (!_shouldBePlaying || channel == null || _reconnecting) return;

    _reconnecting = true;
    try {
      await _player.stop();
      await _player.setUrl(channel.streamUrl);
      if (_shouldBePlaying && _currentChannel?.slug == channel.slug) {
        await _player.play();
        _reconnectAttempt = 0;
        customEvent.add({'type': 'reconnected'});
      }
    } catch (_) {
      customEvent.add({
        'type': 'reconnecting',
        'message': 'Reconectando la transmisión…',
      });
    } finally {
      _reconnecting = false;
      if (_shouldBePlaying && !_player.playing) {
        _scheduleReconnect();
      }
    }
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final channel = RadioStationCatalog.bySlug(mediaId);
    if (channel == null) {
      customEvent.add({
        'type': 'error',
        'message': 'No encontramos la estación solicitada.',
      });
      return;
    }

    await _playChannel(channel);
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name != 'playChannel' || extras == null) {
      return super.customAction(name, extras);
    }

    final metadata = <String, dynamic>{
      'frequency': extras['frequency']?.toString() ?? '',
      'city': extras['city']?.toString() ?? '',
      'callsign': extras['callsign']?.toString() ?? '',
    };

    final channel = Channel(
      id: extras['id'] as int?,
      name: extras['name']?.toString() ?? '',
      slug: extras['slug']?.toString() ?? '',
      streamUrl: extras['stream_url']?.toString() ?? '',
      isActive: extras['is_active'] as bool? ?? true,
      metadata: metadata,
    );

    await _playChannel(channel);
    return null;
  }

  @override
  Future<void> play() async {
    if (_currentChannel == null) return;
    _shouldBePlaying = true;
    try {
      await _player.play();
      _reconnectAttempt = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  @override
  Future<void> pause() async {
    _shouldBePlaying = false;
    _reconnectTimer?.cancel();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _shouldBePlaying = false;
    _reconnectTimer?.cancel();
    _currentChannel = null;
    await _player.stop();
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  void _broadcastState(PlaybackEvent event) {
    if (_player.playing) {
      _reconnectAttempt = 0;
    }

    playbackState.add(
      PlaybackState(
        controls: [
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
          MediaAction.playFromMediaId,
        },
        androidCompactActionIndices: const [0],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
