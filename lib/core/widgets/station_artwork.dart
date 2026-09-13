import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../theme/app_theme.dart';

class StationArtwork extends StatelessWidget {
  const StationArtwork({
    required this.channel,
    this.size = 160,
    this.borderRadius = 28,
    super.key,
  });

  final Channel channel;
  final double size;
  final double borderRadius;

  String get _assetPath {
    if (channel.slug == 'somos-radio-102-9') {
      return 'assets/stations/somos_102_9.webp';
    }

    return 'assets/stations/somos_89_1.webp';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.orange.withValues(alpha: .28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orange.withValues(alpha: .14),
            blurRadius: 28,
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.radio_rounded,
            color: AppTheme.orange,
            size: 48,
          ),
        ),
      ),
    );
  }
}
