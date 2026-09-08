import 'package:flutter/material.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/models/channel.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient, super.key});

  final RadioApiClient apiClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Channel>> _channels;
  Channel? _selectedChannel;

  @override
  void initState() {
    super.initState();
    _channels = widget.apiClient.fetchSomosRadioChannels();
  }

  void _reload() {
    setState(() => _channels = widget.apiClient.fetchSomosRadioChannels());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _channels;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 28),
                    Text(
                      '¿Qué quieres escuchar?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<Channel>>(
                      future: _channels,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return _ApiError(
                            message: snapshot.error.toString(),
                            onRetry: _reload,
                          );
                        }

                        final channels = snapshot.data ?? const <Channel>[];
                        if (channels.isEmpty) {
                          return const _EmptyChannels();
                        }

                        return Column(
                          children: channels
                              .map(
                                (channel) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _StationCard(
                                    channel: channel,
                                    selected: channel.slug == _selectedChannel?.slug,
                                    onTap: () {
                                      setState(() => _selectedChannel = channel);
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const _SectionTitle(title: 'Explora'),
                    const SizedBox(height: 10),
                    const _ExploreGrid(),
                    if (AppConfig.isConceptDemo) ...[
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'Concepto demostrativo · Propuesta no oficial',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_selectedChannel != null)
              _MiniPlayer(
                channel: _selectedChannel!,
                onClose: () => setState(() => _selectedChannel = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppTheme.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.radio_rounded, color: Colors.black, size: 29),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOMOS RADIO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
              ),
              Text(
                'CHIAPAS',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.orange.withValues(alpha: .65)),
          ),
          child: const Text(
            'CONCEPTO',
            style: TextStyle(color: AppTheme.orange, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final Channel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.redAccent),
                        SizedBox(width: 7),
                        Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      channel.frequency,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (channel.city.isNotEmpty)
                      Text(
                        channel.city,
                        style: const TextStyle(color: Colors.white60),
                      ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppTheme.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        letterSpacing: 2.2,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.calendar_month_rounded, 'Programación'),
      (Icons.mic_rounded, 'Participa'),
      (Icons.newspaper_rounded, 'Lo último'),
      (Icons.local_offer_rounded, 'Promociones'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: items
          .map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: AppTheme.orange),
                    const SizedBox(height: 10),
                    Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.channel, required this.onClose});

  final Channel channel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: AppTheme.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(channel.frequency, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    channel.city.isEmpty ? 'Somos Radio' : channel.city,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.black,
              ),
            ),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          ],
        ),
      ),
    );
  }
}

class _ApiError extends StatelessWidget {
  const _ApiError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 34),
            const SizedBox(height: 10),
            const Text('No pudimos cargar las estaciones.'),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Somos Radio aún no tiene canales activos publicados en la API.'),
      ),
    );
  }
}
