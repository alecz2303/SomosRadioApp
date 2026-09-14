import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/models/ad_campaign.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({
    required this.apiClient,
    required this.campaigns,
    super.key,
  });

  final RadioApiClient apiClient;
  final List<AdCampaign> campaigns;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late final PageController _pageController;
  final Set<int> _recordedImpressions = <int>{};
  Timer? _rotationTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.campaigns.isNotEmpty) {
        _recordImpression(widget.campaigns.first);
        _startRotation();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaigns.length != widget.campaigns.length) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _rotationTimer?.cancel();
      if (widget.campaigns.isNotEmpty) {
        _recordImpression(widget.campaigns.first);
        _startRotation();
      }
    }
  }

  void _startRotation() {
    _rotationTimer?.cancel();
    if (widget.campaigns.length <= 1) return;

    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextIndex = (_currentIndex + 1) % widget.campaigns.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _recordImpression(AdCampaign campaign) {
    if (!_recordedImpressions.add(campaign.id)) return;
    unawaited(widget.apiClient.recordAdImpression(campaign.id));
  }

  Future<void> _openAd(AdCampaign campaign) async {
    final target = campaign.targetUrl;
    if (target == null || target.isEmpty) return;

    final uri = Uri.tryParse(target);
    if (uri == null) return;

    unawaited(widget.apiClient.recordAdClick(campaign.id));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.campaigns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Row(
            children: [
              const Text(
                'PUBLICIDAD',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7,
                ),
              ),
              if (widget.campaigns.length > 1) ...[
                const Spacer(),
                Text(
                  '${_currentIndex + 1}/${widget.campaigns.length}',
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 6,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.campaigns.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _recordImpression(widget.campaigns[index]);
              },
              itemBuilder: (context, index) {
                final campaign = widget.campaigns[index];
                return Material(
                  color: const Color(0xFF151515),
                  child: InkWell(
                    onTap: campaign.targetUrl == null
                        ? null
                        : () => _openAd(campaign),
                    child: Image.network(
                      campaign.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white24,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.campaigns.length > 1) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.campaigns.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _currentIndex ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? const Color(0xFFFF7A00)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
