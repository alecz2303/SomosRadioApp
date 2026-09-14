import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/models/ad_campaign.dart';
import '../home/home_page.dart';

class SplashAdPage extends StatefulWidget {
  const SplashAdPage({
    required this.apiClient,
    required this.campaign,
    super.key,
  });

  final RadioApiClient apiClient;
  final AdCampaign campaign;

  @override
  State<SplashAdPage> createState() => _SplashAdPageState();
}

class _SplashAdPageState extends State<SplashAdPage> {
  Timer? _finishTimer;
  Timer? _skipTimer;
  bool _canSkip = false;
  bool _finished = false;
  bool _loadStarted = false;
  bool _imageReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _prepareAd();
  }

  Future<void> _prepareAd() async {
    final imageUrl = widget.campaign.imageUrl.trim();
    if (imageUrl.isEmpty) {
      _finish();
      return;
    }

    try {
      await precacheImage(NetworkImage(imageUrl), context);
      if (!mounted || _finished) return;

      setState(() => _imageReady = true);
      unawaited(widget.apiClient.recordAdImpression(widget.campaign.id));

      _skipTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && !_finished) {
          setState(() => _canSkip = true);
        }
      });

      _finishTimer = Timer(const Duration(seconds: 5), _finish);
    } catch (_) {
      _finish();
    }
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    _finishTimer?.cancel();
    _skipTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => HomePage(apiClient: widget.apiClient),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openAd() async {
    final target = widget.campaign.targetUrl;
    if (target == null || target.isEmpty) return;

    unawaited(widget.apiClient.recordAdClick(widget.campaign.id));
    final uri = Uri.tryParse(target);
    if (uri == null) return;

    _finish();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _skipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_imageReady)
            GestureDetector(
              onTap: widget.campaign.targetUrl == null ? null : _openAd,
              child: ColoredBox(
                color: Colors.black,
                child: SafeArea(
                  bottom: false,
                  child: Image.network(
                    widget.campaign.imageUrl,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF0B0B0B),
                    ),
                  ),
                ),
              ),
            )
          else
            const ColoredBox(
              color: Color(0xFF0B0B0B),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_imageReady)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .62),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PUBLICIDAD',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _canSkip ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_canSkip,
                            child: TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.black.withValues(alpha: .62),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                              ),
                              child: const Text(
                                'Omitir',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (widget.campaign.targetUrl != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .62),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Toca la imagen para conocer más',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
