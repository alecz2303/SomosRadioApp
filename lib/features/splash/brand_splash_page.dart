import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api/radio_api_client.dart';
import '../home/home_page.dart';

class BrandSplashPage extends StatefulWidget {
  const BrandSplashPage({super.key});

  @override
  State<BrandSplashPage> createState() => _BrandSplashPageState();
}

class _BrandSplashPageState extends State<BrandSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _timer = Timer(const Duration(milliseconds: 1400), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomePage(apiClient: RadioApiClient()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OrangeGlow(),
          const _AudioWaveDecoration(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SvgPicture.asset(
                        'assets/branding/somos_logo.svg',
                        width: 290,
                        semanticsLabel: 'Somos FM Radio',
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '89.1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                        SizedBox(width: 18),
                        SizedBox(
                          height: 22,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 2,
                            color: Color(0xFFFF8A00),
                          ),
                        ),
                        SizedBox(width: 18),
                        Text(
                          '102.9',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _LoadingBar(),
                  const Spacer(flex: 5),
                  const Text(
                    'Concepto demostrativo · Propuesta no oficial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF787878),
                      fontSize: 10,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeGlow extends StatelessWidget {
  const _OrangeGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.85, -0.95),
          radius: 1.15,
          colors: [
            Color(0x3DFF8A00),
            Color(0x12000000),
            Color(0xFF0B0B0B),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: Curves.easeOutCubic.transform(_controller.value),
              minHeight: 3,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8A00)),
            );
          },
        ),
      ),
    );
  }
}

class _AudioWaveDecoration extends StatelessWidget {
  const _AudioWaveDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AudioWavePainter(),
      ),
    );
  }
}

class _AudioWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33FF8A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final baseY = size.height * 0.72;
    for (var line = 0; line < 7; line++) {
      final path = Path();
      final amplitude = 18.0 + (line * 6);
      final offset = line * 8.0;
      for (double x = 0; x <= size.width; x += 6) {
        final progress = x / size.width;
        final y = baseY +
            offset +
            amplitude *
                (0.55 - progress).abs() *
                (progress < 0.5 ? 1 : -1);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
