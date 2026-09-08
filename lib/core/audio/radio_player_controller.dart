import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../models/channel.dart';
import 'audio_service_manager.dart';
import 'radio_audio_handler.dart';

class RadioPlayerController extends ChangeNotifier {
  RadioPlayerController() {
    _playbackSubscription = radioAudioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == AudioProcessingState.loading ||
          state.processingState == AudioProcessingState.buffering;
      notifyListeners();
    });

    _mediaItemSubscription = radioAudioHandler.mediaItem.listen((item) {
      currentChannel = item == null ? null : _channelFromMediaItem(item);
      notifyListeners();
    });

    _eventSubscription = radioAudioHandler.customEvent.listen((event) {
      if (event is Map && event['type'] == 'error') {
        errorMessage = event['message']?.toString();
        notifyListeners();
      }
    });

    final state = radioAudioHandler.playbackState.value;
    _isPlaying = state.playing;
    _isBuffering = state.processingState == AudioProcessingState.loading ||
        state.processingState == AudioProcessingState.buffering;

    final item = radioAudioHandler.mediaItem.value;
    if (item != null) currentChannel = _channelFromMediaItem(item);
  }

  late final StreamSubscription<PlaybackState> _playbackSubscription;
  late final StreamSubscription<MediaItem?> _mediaItemSubscription;
  late final StreamSubscription<dynamic> _eventSubscription;

  Channel? currentChannel;
  String? errorMessage;
  bool _isPlaying = false;
  bool _isBuffering = false;
  List<Channel> _availableChannels = const [];

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  List<Channel> get availableChannels => List.unmodifiable(_availableChannels);

  void setAvailableChannels(List<Channel> channels) {
    _availableChannels = List.unmodifiable(channels);
    notifyListeners();
  }

  Future<void> playChannel(Channel channel) async {
    errorMessage = null;

    try {
      if (currentChannel?.slug == channel.slug) {
        await toggle();
        return;
      }

      await radioAudioHandler.customAction('playChannel', {
        'id': channel.id,
        'name': channel.name,
        'slug': channel.slug,
        'stream_url': channel.streamUrl,
        'is_active': channel.isActive,
        'frequency': channel.frequency,
        'city': channel.city,
        'callsign': channel.callsign,
      });
    } catch (_) {
      errorMessage = 'No fue posible iniciar la transmisión.';
      notifyListeners();
    }
  }

  Future<void> playFromWidget(String slug) async {
    errorMessage = null;
    try {
      await radioAudioHandler.playFromMediaId(slug);
    } catch (_) {
      errorMessage = 'No fue posible iniciar la transmisión.';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (currentChannel == null) return;

    if (_isPlaying) {
      await radioAudioHandler.pause();
    } else {
      await radioAudioHandler.play();
    }
  }

  Future<void> stop() async {
    await radioAudioHandler.stop();
    errorMessage = null;
  }

  Channel _channelFromMediaItem(MediaItem item) {
    final extras = item.extras ?? const <String, dynamic>{};
    final known = RadioStationCatalog.bySlug(item.id);

    return Channel(
      id: extras['channel_id'] as int? ?? known?.id,
      name: extras['name']?.toString() ?? known?.name ?? item.displayTitle ?? item.title,
      slug: extras['slug']?.toString() ?? item.id,
      streamUrl: extras['stream_url']?.toString() ?? known?.streamUrl ?? '',
      isActive: extras['is_active'] as bool? ?? true,
      metadata: {
        'frequency': extras['frequency']?.toString() ?? known?.frequency ?? item.title,
        'city': extras['city']?.toString() ?? known?.city ?? item.artist ?? '',
        'callsign': extras['callsign']?.toString() ?? known?.callsign ?? '',
      },
    );
  }

  @override
  void dispose() {
    unawaited(_playbackSubscription.cancel());
    unawaited(_mediaItemSubscription.cancel());
    unawaited(_eventSubscription.cancel());
    super.dispose();
  }
}
