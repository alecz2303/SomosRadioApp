import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/splash/brand_splash_page.dart';

class SomosRadioApp extends StatelessWidget {
  const SomosRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somos Radio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BrandSplashPage(),
    );
  }
}
