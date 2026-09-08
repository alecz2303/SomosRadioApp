import 'package:audio_service/audio_service.dart';

import 'radio_audio_handler.dart';

late final AudioHandler radioAudioHandler;

Future<void> initializeRadioAudioService() async {
  radioAudioHandler = await AudioService.init(
    builder: RadioAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.alecz.somos_radio.audio',
      androidNotificationChannelName: 'Somos Radio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );
}
