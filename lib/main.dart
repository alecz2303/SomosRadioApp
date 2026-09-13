import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/somos_radio_app.dart';
import 'core/audio/audio_service_manager.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeRadioAudioService();

  try {
    await PushNotificationService.initialize();
  } catch (error) {
    debugPrint('Push notifications initialization failed: $error');
  }

  runApp(const SomosRadioApp());
}
