import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/channel.dart';

class RadioPlayerController extends ChangeNotifier {
  RadioPlayerController() {
    _playingSubscription = _player.playingStream.listen((_) => notifyListeners());
    _stateSubscription = _player.processingStateStream.listen((_) => notifyListeners());
    _errorSubscription = _player.errorStream.listen((error) {
      errorMessage = error.message;
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();

  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<ProcessingState> _stateSubscription;
  late final StreamSubscription<PlayerException> _errorSubscription;

  Channel? currentChannel;
  String? errorMessage;
  bool _switchingStation = false;
  List<Channel> _availableChannels = const [];

  bool get isPlaying => _player.playing;

  bool get isBuffering =>
      _switchingStation ||
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;

  List<Channel> get availableChannels => List.unmodifiable(_availableChannels);

  void setAvailableChannels(List<Channel> channels) {
    _availableChannels = List.unmodifiable(channels);
    notifyListeners();
  }

  Future<void> playChannel(Channel channel) async {
    if (channel.streamUrl.trim().isEmpty) {
      errorMessage = 'Esta estación todavía no tiene un stream publicado.';
      notifyListeners();
      return;
    }

    errorMessage = null;

    if (currentChannel?.slug == channel.slug) {
      if (_player.playing) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
      notifyListeners();
      return;
    }

    currentChannel = channel;
    _switchingStation = true;
    notifyListeners();

    try {
      final title = channel.frequency.isNotEmpty ? channel.frequency : channel.name;
      final subtitle = channel.city.isNotEmpty ? channel.city : 'Chiapas';

      // just_audio_background can retain the previous MediaItem in Android's
      // media notification when replacing one live stream directly with another.
      // Stopping first forces Android to release the current media item so the
      // new station metadata is published immediately.
      await _player.stop();

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(channel.streamUrl),
          tag: MediaItem(
            id: channel.slug,
            album: 'Somos Radio Chiapas',
            title: title,
            artist: subtitle,
            displayTitle: channel.displayName,
            displaySubtitle: subtitle,
            isLive: true,
          ),
        ),
      );
      _switchingStation = false;
      notifyListeners();
      unawaited(_player.play());
    } on PlayerException catch (error) {
      _switchingStation = false;
      errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _switchingStation = false;
      errorMessage = 'No fue posible iniciar la transmisión.';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (currentChannel == null) return;

    if (_player.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    currentChannel = null;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_playingSubscription.cancel());
    unawaited(_stateSubscription.cancel());
    unawaited(_errorSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
