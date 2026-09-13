import 'package:flutter/material.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/audio/radio_player_controller.dart';
import '../../core/models/channel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/station_artwork.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _apiClient = RadioApiClient();
  late final RadioPlayerController _player;
  late Future<List<Channel>> _channels;

  @override
  void initState() {
    super.initState();
    _player = RadioPlayerController()..addListener(_onPlayerChanged);
    _channels = _loadChannels();
  }

  Future<List<Channel>> _loadChannels() async {
    final channels = await _apiClient.fetchSomosRadioChannels();
    _player.setAvailableChannels(channels);
    return channels;
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(Channel channel) async {
    await _player.playChannel(channel);
    if (!mounted || _player.errorMessage == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_player.errorMessage!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('En vivo')),
      body: SafeArea(
        child: FutureBuilder<List<Channel>>(
          future: _channels,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 44),
                      const SizedBox(height: 12),
                      const Text('No pudimos cargar las estaciones.'),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => setState(() => _channels = _loadChannels()),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final channels = snapshot.data ?? const <Channel>[];
            if (channels.isEmpty) {
              return const Center(child: Text('No hay estaciones disponibles.'));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                const Text(
                  'Escucha Somos Radio',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige una estación para escuchar la transmisión en vivo.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                ...channels.map((channel) {
                  final selected = _player.currentChannel?.slug == channel.slug;
                  final playing = selected && _player.isPlaying;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: InkWell(
                        onTap: () => _play(channel),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              StationArtwork(channel: channel, size: 72, borderRadius: 18),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EN VIVO',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      channel.frequency,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (channel.city.isNotEmpty)
                                      Text(
                                        channel.city,
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.black,
                                child: _player.isBuffering && selected
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
