import 'package:flutter/material.dart';

import 'app/somos_radio_app.dart';
import 'core/audio/audio_service_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeRadioAudioService();
  runApp(const SomosRadioApp());
}
