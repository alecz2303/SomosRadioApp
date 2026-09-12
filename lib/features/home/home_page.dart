import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/audio/radio_player_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/models/channel.dart';
import '../../core/theme/app_theme.dart';
import '../news/latest_content_page.dart';
import '../participation/song_request_page.dart';
import '../promotions/promotions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient, super.key});

  final RadioApiClient apiClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Channel>> _channels;
  late final RadioPlayerController _radioPlayer;

  @override
  void initState() {
    super.initState();
    _radioPlayer = RadioPlayerController()..addListener(_onPlayerChanged);
    _channels = _loadChannels();
  }

  Future<List<Channel>> _loadChannels() async {
    final channels = await widget.apiClient.fetchSomosRadioChannels();
    _radioPlayer.setAvailableChannels(channels);
    return channels;
  }

  @override
  void dispose() {
    _radioPlayer.removeListener(_onPlayerChanged);
    _radioPlayer.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  void _reload() {
    setState(() => _channels = _loadChannels());
  }

  Future<void> _playChannel(Channel channel) async {
    await _radioPlayer.playChannel(channel);
    if (!mounted || _radioPlayer.errorMessage == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_radioPlayer.errorMessage!)));
  }

  void _showNowPlaying(BuildContext sheetContext) {
    final channel = _radioPlayer.currentChannel;
    if (channel == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Elige una estación para escuchar en vivo.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedBuilder(
        animation: _radioPlayer,
        builder: (context, _) {
          final activeChannel = _radioPlayer.currentChannel ?? channel;
          return _NowPlayingSheet(
            channel: activeChannel,
            channels: _radioPlayer.availableChannels,
            isPlaying: _radioPlayer.isPlaying,
            isBuffering: _radioPlayer.isBuffering,
            onToggle: _radioPlayer.toggle,
            onSelectChannel: _radioPlayer.playChannel,
          );
        },
      ),
    );
  }

  void _pushWithPersistentPlayer(Widget page, int selectedIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PersistentPlayerRoute(
          radioPlayer: _radioPlayer,
          child: page,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }

  void _openParticipate() {
    _pushWithPersistentPlayer(const _ParticipatePage(), 2);
  }

  void _openLatest() {
    _pushWithPersistentPlayer(const LatestContentPage(), 3);
  }

  void _openPromotions() {
    _pushWithPersistentPlayer(const PromotionsPage(), 0);
  }

  void _onNavigationSelected(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        _showNowPlaying(context);
        break;
      case 2:
        _openParticipate();
        break;
      case 3:
        _openLatest();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = _radioPlayer.currentChannel;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final nextChannels = _loadChannels();
            setState(() => _channels = nextChannels);
            await nextChannels;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              const _BrandHeader(),
              const SizedBox(height: 28),
              Text(
                '¿Qué quieres escuchar?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white70),
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
                  if (channels.isEmpty) return const _EmptyChannels();

                  return Column(
                    children: channels
                        .map(
                          (channel) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _StationCard(
                              channel: channel,
                              selected: channel.slug == currentChannel?.slug,
                              playing: channel.slug == currentChannel?.slug &&
                                  _radioPlayer.isPlaying,
                              buffering: channel.slug == currentChannel?.slug &&
                                  _radioPlayer.isBuffering,
                              onTap: () => _playChannel(channel),
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
              _ExploreGrid(
                onParticipate: _openParticipate,
                onLatest: _openLatest,
                onPromotions: _openPromotions,
              ),
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentChannel != null)
            _MiniPlayer(
              channel: currentChannel,
              isPlaying: _radioPlayer.isPlaying,
              isBuffering: _radioPlayer.isBuffering,
              errorMessage: _radioPlayer.errorMessage,
              onTap: () => _showNowPlaying(context),
              onToggle: _radioPlayer.toggle,
              onClose: _radioPlayer.stop,
            ),
          _AppNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: _onNavigationSelected,
          ),
        ],
      ),
    );
  }
}

class _PersistentPlayerRoute extends StatelessWidget {
  const _PersistentPlayerRoute({
    required this.radioPlayer,
    required this.child,
    required this.selectedIndex,
  });

  final RadioPlayerController radioPlayer;
  final Widget child;
  final int selectedIndex;

  void _showNowPlaying(BuildContext context) {
    final channel = radioPlayer.currentChannel;
    if (channel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una estación desde Inicio.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedBuilder(
        animation: radioPlayer,
        builder: (context, _) {
          final activeChannel = radioPlayer.currentChannel ?? channel;
          return _NowPlayingSheet(
            channel: activeChannel,
            channels: radioPlayer.availableChannels,
            isPlaying: radioPlayer.isPlaying,
            isBuffering: radioPlayer.isBuffering,
            onToggle: radioPlayer.toggle,
            onSelectChannel: radioPlayer.playChannel,
          );
        },
      ),
    );
  }

  void _replace(BuildContext context, Widget page, int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _PersistentPlayerRoute(
          radioPlayer: radioPlayer,
          child: page,
          selectedIndex: index,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) {
      if (index == 1) _showNowPlaying(context);
      return;
    }

    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        _showNowPlaying(context);
        break;
      case 2:
        _replace(context, const _ParticipatePage(), 2);
        break;
      case 3:
        _replace(context, const LatestContentPage(), 3);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: radioPlayer,
      builder: (context, _) {
        final channel = radioPlayer.currentChannel;
        return Scaffold(
          body: child,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (channel != null)
                _MiniPlayer(
                  channel: channel,
                  isPlaying: radioPlayer.isPlaying,
                  isBuffering: radioPlayer.isBuffering,
                  errorMessage: radioPlayer.errorMessage,
                  onTap: () => _showNowPlaying(context),
                  onToggle: radioPlayer.toggle,
                  onClose: radioPlayer.stop,
                ),
              _AppNavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _navigate(context, index),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: const Color(0xFF090909),
      indicatorColor: AppTheme.orange,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: Colors.black),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.radio_outlined),
          selectedIcon: Icon(Icons.radio_rounded, color: Colors.black),
          label: 'En vivo',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic_none_rounded),
          selectedIcon: Icon(Icons.mic_rounded, color: Colors.black),
          label: 'Participa',
        ),
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper_rounded, color: Colors.black),
          label: 'Lo último',
        ),
      ],
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
    required this.playing,
    required this.buffering,
    required this.onTap,
  });

  final Channel channel;
  final bool selected;
  final bool playing;
  final bool buffering;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [channel.city, channel.callsign]
        .where((value) => value.isNotEmpty)
        .join(' · ');

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
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(color: Colors.white60)),
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
                alignment: Alignment.center,
                child: buffering
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
  const _ExploreGrid({
    required this.onParticipate,
    required this.onLatest,
    required this.onPromotions,
  });

  final VoidCallback onParticipate;
  final VoidCallback onLatest;
  final VoidCallback onPromotions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        const _ExploreCard(
          icon: Icons.calendar_month_rounded,
          title: 'Programación',
          subtitle: 'Próximamente',
        ),
        _ExploreCard(
          icon: Icons.mic_rounded,
          title: 'Participa',
          subtitle: 'Habla con Somos',
          onTap: onParticipate,
        ),
        _ExploreCard(
          icon: Icons.newspaper_rounded,
          title: 'Lo último',
          subtitle: 'Contenido real',
          onTap: onLatest,
        ),
        _ExploreCard(
          icon: Icons.local_offer_rounded,
          title: 'Promociones',
          onTap: onPromotions,
        ),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.orange),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipatePage extends StatelessWidget {
  const _ParticipatePage();

  Future<void> _whatsapp(
    BuildContext context,
    String number,
    String station,
  ) async {
    final text = Uri.encodeComponent(
      'Hola Somos Radio, les escribo desde la app. Estoy escuchando $station.',
    );
    final uri = Uri.parse('https://wa.me/$number?text=$text');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir WhatsApp.')),
      );
    }
  }

  void _openSongRequest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SongRequestPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participa')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.forum_rounded, color: AppTheme.orange, size: 54),
            const SizedBox(height: 18),
            Text(
              'Tu voz también es parte de Somos',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Participa directamente desde la app o escríbenos por WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.45),
            ),
            const SizedBox(height: 28),
            _ActionFeature(
              icon: Icons.music_note_rounded,
              title: 'Pide tu canción',
              text: 'Envía canción, artista y dedicatoria al panel de Somos Radio.',
              onTap: () => _openSongRequest(context),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(title: 'WhatsApp'),
            const SizedBox(height: 12),
            _ContactCard(
              title: 'Somos Radio 89.1 FM',
              subtitle: 'Tuxtla Gutiérrez',
              number: '+52 961 119 3641',
              onTap: () => _whatsapp(
                context,
                '529611193641',
                'Somos Radio 89.1 FM',
              ),
            ),
            const SizedBox(height: 12),
            _ContactCard(
              title: 'Somos Radio 102.9 FM',
              subtitle: 'San Cristóbal de las Casas',
              number: '+52 967 678 2403',
              onTap: () => _whatsapp(
                context,
                '529676782403',
                'Somos Radio 102.9 FM',
              ),
            ),
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Más formas de participar'),
            const SizedBox(height: 12),
            const _FutureFeature(
              icon: Icons.emoji_events_rounded,
              title: 'Concursos y dinámicas',
              text: 'Un espacio para activar promociones y participación desde la app.',
            ),
            const _FutureFeature(
              icon: Icons.poll_rounded,
              title: 'Encuestas',
              text: 'La audiencia podrá votar y participar en contenidos interactivos.',
            ),
            if (AppConfig.isConceptDemo) ...[
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Concepto demostrativo · Propuesta no oficial',
                  style: TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionFeature extends StatelessWidget {
  const _ActionFeature({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.orange,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_rounded, color: AppTheme.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      number,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.orange,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureFeature extends StatelessWidget {
  const _FutureFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.channel,
    required this.isPlaying,
    required this.isBuffering,
    required this.errorMessage,
    required this.onTap,
    required this.onToggle,
    required this.onClose,
  });

  final Channel channel;
  final bool isPlaying;
  final bool isBuffering;
  final String? errorMessage;
  final VoidCallback onTap;
  final Future<void> Function() onToggle;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  color: AppTheme.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        errorMessage ?? '${channel.city} · En vivo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: errorMessage == null
                              ? Colors.white54
                              : Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isBuffering ? null : () => onToggle(),
                  icon: isBuffering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppTheme.orange,
                    disabledForegroundColor: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => onClose(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingSheet extends StatelessWidget {
  const _NowPlayingSheet({
    required this.channel,
    required this.channels,
    required this.isPlaying,
    required this.isBuffering,
    required this.onToggle,
    required this.onSelectChannel,
  });

  final Channel channel;
  final List<Channel> channels;
  final bool isPlaying;
  final bool isBuffering;
  final Future<void> Function() onToggle;
  final Future<void> Function(Channel channel) onSelectChannel;

  @override
  Widget build(BuildContext context) {
    final stationSubtitle = [channel.city, channel.callsign]
        .where((value) => value.isNotEmpty)
        .join(' · ');

    return Container(
      height: MediaQuery.sizeOf(context).height * .78,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 9, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.radio_rounded, size: 76, color: Colors.black),
              ),
              const SizedBox(height: 22),
              Text(
                'SOMOS RADIO',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                channel.frequency,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              ),
              if (stationSubtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  stationSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
              if (channels.length > 1) ...[
                const SizedBox(height: 22),
                const Text(
                  'CAMBIAR ESTACIÓN',
                  style: TextStyle(
                    color: Colors.white38,
                    letterSpacing: 1.7,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: channels.take(2).map((candidate) {
                    final selected = candidate.slug == channel.slug;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _StationSwitchButton(
                          channel: candidate,
                          selected: selected,
                          disabled: isBuffering,
                          onTap: () => onSelectChannel(candidate),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 78,
                height: 78,
                child: IconButton(
                  onPressed: isBuffering ? null : () => onToggle(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppTheme.orange,
                  ),
                  icon: isBuffering
                      ? const SizedBox(
                          width: 27,
                          height: 27,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 44,
                        ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Transmisión en vivo',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationSwitchButton extends StatelessWidget {
  const _StationSwitchButton({
    required this.channel,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final Channel channel;
  final bool selected;
  final bool disabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.orange : Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: selected || disabled ? null : () => onTap(),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.orange : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Text(
                channel.frequency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                channel.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.black54 : Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
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
        child: Text(
          'Somos Radio aún no tiene canales activos publicados en la API.',
        ),
      ),
    );
  }
}
