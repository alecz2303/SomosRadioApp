import 'dart:io';

import 'package:audio_service/audio_service.dart';

import 'native_media3_audio_handler.dart';
import 'radio_audio_handler.dart';

late final AudioHandler radioAudioHandler;

Future<void> initializeRadioAudioService() async {
  if (Platform.isAndroid) {
    radioAudioHandler = NativeMedia3AudioHandler();
    return;
  }

  radioAudioHandler = await AudioService.init(
    builder: RadioAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.alecz.somos_radio.audio',
      androidNotificationChannelName: 'Somos Radio · En vivo',
      androidNotificationChannelDescription: 'Controles de reproducción de Somos Radio',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );
}
