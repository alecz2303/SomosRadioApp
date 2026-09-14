import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/models/ad_campaign.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({
    required this.apiClient,
    required this.campaign,
    super.key,
  });

  final RadioApiClient apiClient;
  final AdCampaign campaign;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _impressionRecorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordImpression());
  }

  Future<void> _recordImpression() async {
    if (_impressionRecorded) return;
    _impressionRecorded = true;
    await widget.apiClient.recordAdImpression(widget.campaign.id);
  }

  Future<void> _openAd() async {
    final target = widget.campaign.targetUrl;
    if (target == null || target.isEmpty) return;

    await widget.apiClient.recordAdClick(widget.campaign.id);
    final uri = Uri.tryParse(target);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'PUBLICIDAD',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: const Color(0xFF151515),
            child: InkWell(
              onTap: widget.campaign.targetUrl == null ? null : _openAd,
              child: AspectRatio(
                aspectRatio: 16 / 6,
                child: Image.network(
                  widget.campaign.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
