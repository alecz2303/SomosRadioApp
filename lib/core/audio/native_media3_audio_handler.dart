import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

import '../models/channel.dart';
import 'radio_audio_handler.dart';

class NativeMedia3AudioHandler extends BaseAudioHandler {
  NativeMedia3AudioHandler() {
    _subscription = _events.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) _applyState(Map<Object?, Object?>.from(event));
      },
      onError: (_) {},
    );
    unawaited(_refreshState());
  }

  static const _methods = MethodChannel('com.alecz.somos_radio/media3');
  static const _events = EventChannel('com.alecz.somos_radio/media3_events');

  late final StreamSubscription<dynamic> _subscription;
  Channel? _currentChannel;

  Future<void> _refreshState() async {
    try {
      final state = await _methods.invokeMapMethod<Object?, Object?>('state');
      if (state != null) _applyState(state);
    } catch (_) {}
  }

  MediaItem _itemFor(Channel channel) => MediaItem(
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

  Future<void> _playChannel(Channel channel) async {
    if (channel.streamUrl.trim().isEmpty) {
      customEvent.add({
        'type': 'error',
        'message': 'Esta estación todavía no tiene un stream publicado.',
      });
      return;
    }

    _currentChannel = channel;
    mediaItem.add(_itemFor(channel));

    try {
      await _methods.invokeMethod<void>('playChannel', {
        'slug': channel.slug,
        'stream_url': channel.streamUrl,
        'name': channel.displayName,
        'city': channel.city,
        'artwork_url': RadioStationCatalog.artworkUri(channel.slug)?.toString(),
      });
    } catch (_) {
      customEvent.add({
        'type': 'error',
        'message': 'No fue posible iniciar la transmisión.',
      });
      rethrow;
    }
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    final channel = RadioStationCatalog.bySlug(mediaId);
    if (channel == null) {
      customEvent.add({'type': 'error', 'message': 'No encontramos la estación solicitada.'});
      return;
    }
    await _playChannel(channel);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name != 'playChannel' || extras == null) {
      return super.customAction(name, extras);
    }

    final channel = Channel(
      id: extras['id'] as int?,
      name: extras['name']?.toString() ?? '',
      slug: extras['slug']?.toString() ?? '',
      streamUrl: extras['stream_url']?.toString() ?? '',
      isActive: extras['is_active'] as bool? ?? true,
      metadata: {
        'frequency': extras['frequency']?.toString() ?? '',
        'city': extras['city']?.toString() ?? '',
        'callsign': extras['callsign']?.toString() ?? '',
      },
    );
    await _playChannel(channel);
    return null;
  }

  @override
  Future<void> play() => _methods.invokeMethod<void>('play');

  @override
  Future<void> pause() => _methods.invokeMethod<void>('pause');

  @override
  Future<void> stop() async {
    await _methods.invokeMethod<void>('stop');
    _currentChannel = null;
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  void _applyState(Map<Object?, Object?> state) {
    final playing = state['playing'] == true;
    final nativeState = state['playback_state'] as int? ?? 1;
    final mediaId = state['media_id']?.toString();

    if (mediaId != null && mediaId.isNotEmpty) {
      final known = RadioStationCatalog.bySlug(mediaId);
      if (known != null) {
        _currentChannel = known;
        mediaItem.add(_itemFor(known));
      }
    }

    final processingState = switch (nativeState) {
      2 => AudioProcessingState.buffering,
      3 => AudioProcessingState.ready,
      4 => AudioProcessingState.completed,
      _ => AudioProcessingState.idle,
    };

    playbackState.add(
      PlaybackState(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
          MediaAction.playFromMediaId,
        },
        androidCompactActionIndices: const [0],
        processingState: processingState,
        playing: playing,
      ),
    );
  }
}
