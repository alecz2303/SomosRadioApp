import 'dart:async';

import 'package:flutter/material.dart';

import '../core/audio/audio_service_manager.dart';
import '../core/notifications/push_navigation.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/persistent_audio_bar.dart';
import '../features/live/live_page.dart';
import '../features/news/latest_content_page.dart';
import '../features/participation/contest_page.dart';
import '../features/participation/song_request_page.dart';
import '../features/splash/brand_splash_page.dart';

class SomosRadioApp extends StatefulWidget {
  const SomosRadioApp({super.key});

  @override
  State<SomosRadioApp> createState() => _SomosRadioAppState();
}

class _SomosRadioAppState extends State<SomosRadioApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _initialActionTimer;

  @override
  void initState() {
    super.initState();
    PushNavigation.pendingAction.addListener(_onPushAction);

    _initialActionTimer = Timer(const Duration(milliseconds: 1700), () {
      _handleAction(PushNavigation.pendingAction.value);
    });
  }

  @override
  void dispose() {
    _initialActionTimer?.cancel();
    PushNavigation.pendingAction.removeListener(_onPushAction);
    super.dispose();
  }

  void _onPushAction() {
    final action = PushNavigation.pendingAction.value;
    if (action == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAction(action);
    });
  }

  Future<void> _handleAction(String? action) async {
    if (action == null || action.isEmpty) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    Widget? destination;

    if (action.startsWith('play:')) {
      final stationSlug = action.substring('play:'.length).trim();
      if (stationSlug.isEmpty) {
        PushNavigation.clear(action);
        return;
      }

      PushNavigation.clear(action);
      await radioAudioHandler.playFromMediaId(stationSlug);
      if (!mounted) return;
      destination = const LivePage();
    } else {
      switch (action) {
        case 'live':
          destination = const LivePage();
          break;
        case 'participate':
          destination = const SongRequestPage();
          break;
        case 'contest':
          destination = const ContestPage();
          break;
        case 'latest':
          destination = const LatestContentPage();
          break;
        default:
          PushNavigation.clear(action);
          return;
      }
      PushNavigation.clear(action);
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => PersistentAudioBar(child: destination!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Somos Radio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BrandSplashPage(),
    );
  }
}
