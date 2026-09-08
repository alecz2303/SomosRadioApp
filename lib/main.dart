import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/somos_radio_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.alecz.somos_radio.audio',
    androidNotificationChannelName: 'Somos Radio',
    androidNotificationOngoing: true,
  );

  runApp(const SomosRadioApp());
}
