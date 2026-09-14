import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/audio/radio_player_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/models/ad_campaign.dart';
import '../../core/models/channel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/station_artwork.dart';
import '../ads/ad_banner.dart';
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
  late Future<List<AdCampaign>> _homeAds;
  late final RadioPlayerController _radioPlayer;

  @override
  void initState() {
    super.initState();
    _radioPlayer = RadioPlayerController()..addListener(_onPlayerChanged);
    _channels = _loadChannels();
    _homeAds = widget.apiClient.fetchAds(placement: 'home');
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

  void _openParticipate() => _pushWithPersistentPlayer(const _ParticipatePage(), 2);
  void _openLatest() => _pushWithPersistentPlayer(const LatestContentPage(), 3);
  void _openPromotions() => _pushWithPersistentPlayer(const PromotionsPage(), 0);

  void _onNavigationSelected(int index) {
    switch (index) {
      case 0: break;
      case 1: _showNowPlaying(context); break;
      case 2: _openParticipate(); break;
      case 3: _openLatest(); break;
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
            final nextAds = widget.apiClient.fetchAds(placement: 'home');
            setState(() { _channels = nextChannels; _homeAds = nextAds; });
            await Future.wait([nextChannels, nextAds]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              const _BrandHeader(),
              const SizedBox(height: 28),
              Text('¿Qué quieres escuchar?', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 14),
              FutureBuilder<List<Channel>>(
                future: _channels,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                  if (snapshot.hasError) return _ApiError(message: snapshot.error.toString(), onRetry: _reload);
                  final channels = snapshot.data ?? const <Channel>[];
                  if (channels.isEmpty) return const _EmptyChannels();
                  return Column(children: channels.map((channel) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _StationCard(channel: channel, selected: channel.slug == currentChannel?.slug, playing: channel.slug == currentChannel?.slug && _radioPlayer.isPlaying, buffering: channel.slug == currentChannel?.slug && _radioPlayer.isBuffering, onTap: () => _playChannel(channel)),
                  )).toList());
                },
              ),
              FutureBuilder<List<AdCampaign>>(
                future: _homeAds,
                builder: (context, snapshot) {
                  final ads = snapshot.data ?? const <AdCampaign>[];
                  if (ads.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 22),
                    child: AdBanner(apiClient: widget.apiClient, campaign: ads.first),
                  );
                },
              ),
              const _SectionTitle(title: 'Explora'),
              const SizedBox(height: 10),
              _ExploreGrid(onParticipate: _openParticipate, onLatest: _openLatest, onPromotions: _openPromotions),
              if (AppConfig.isConceptDemo) ...[
                const SizedBox(height: 28),
                const Center(child: Text('Concepto demostrativo · Propuesta no oficial', style: TextStyle(color: Colors.white38, fontSize: 11))),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (currentChannel != null) _MiniPlayer(channel: currentChannel, isPlaying: _radioPlayer.isPlaying, isBuffering: _radioPlayer.isBuffering, errorMessage: _radioPlayer.errorMessage, onTap: () => _showNowPlaying(context), onToggle: _radioPlayer.toggle, onClose: _radioPlayer.stop),
        _AppNavigationBar(selectedIndex: 0, onDestinationSelected: _onNavigationSelected),
      ]),
    );
  }
}

class _PersistentPlayerRoute extends StatelessWidget {
  const _PersistentPlayerRoute({required this.radioPlayer, required this.child, required this.selectedIndex});
  final RadioPlayerController radioPlayer;
  final Widget child;
  final int selectedIndex;
  void _showNowPlaying(BuildContext context) {
    final channel = radioPlayer.currentChannel;
    if (channel == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elige una estación desde Inicio.'))); return; }
    showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AnimatedBuilder(animation: radioPlayer, builder: (context, _) { final activeChannel = radioPlayer.currentChannel ?? channel; return _NowPlayingSheet(channel: activeChannel, channels: radioPlayer.availableChannels, isPlaying: radioPlayer.isPlaying, isBuffering: radioPlayer.isBuffering, onToggle: radioPlayer.toggle, onSelectChannel: radioPlayer.playChannel); }));
  }
  void _replace(BuildContext context, Widget page, int index) { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => _PersistentPlayerRoute(radioPlayer: radioPlayer, child: page, selectedIndex: index))); }
  void _navigate(BuildContext context, int index) { if (index == selectedIndex) { if (index == 1) _showNowPlaying(context); return; } switch (index) { case 0: Navigator.of(context).popUntil((route) => route.isFirst); break; case 1: _showNowPlaying(context); break; case 2: _replace(context, const _ParticipatePage(), 2); break; case 3: _replace(context, const LatestContentPage(), 3); break; } }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: radioPlayer, builder: (context, _) { final channel = radioPlayer.currentChannel; return Scaffold(body: child, bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [if (channel != null) _MiniPlayer(channel: channel, isPlaying: radioPlayer.isPlaying, isBuffering: radioPlayer.isBuffering, errorMessage: radioPlayer.errorMessage, onTap: () => _showNowPlaying(context), onToggle: radioPlayer.toggle, onClose: radioPlayer.stop), _AppNavigationBar(selectedIndex: selectedIndex, onDestinationSelected: (index) => _navigate(context, index))])); });
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({required this.selectedIndex, required this.onDestinationSelected}); final int selectedIndex; final ValueChanged<int> onDestinationSelected;
  @override Widget build(BuildContext context) => NavigationBar(selectedIndex: selectedIndex, onDestinationSelected: onDestinationSelected, backgroundColor: const Color(0xFF090909), indicatorColor: AppTheme.orange, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Colors.black), label: 'Inicio'), NavigationDestination(icon: Icon(Icons.radio_outlined), selectedIcon: Icon(Icons.radio_rounded, color: Colors.black), label: 'En vivo'), NavigationDestination(icon: Icon(Icons.mic_none_rounded), selectedIcon: Icon(Icons.mic_rounded, color: Colors.black), label: 'Participa'), NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper_rounded, color: Colors.black), label: 'Lo último')]);
}

class _BrandHeader extends StatelessWidget { const _BrandHeader(); @override Widget build(BuildContext context) => Row(children: [Container(width: 50, height: 50, decoration: const BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle), child: const Icon(Icons.radio_rounded, color: Colors.black, size: 29)), const SizedBox(width: 13), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SOMOS RADIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23)), Text('CHIAPAS', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 10))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppTheme.orange.withValues(alpha: .65))), child: const Text('CONCEPTO', style: TextStyle(color: AppTheme.orange, fontSize: 9)))]); }

class _StationCard extends StatelessWidget {
  const _StationCard({required this.channel, required this.selected, required this.playing, required this.buffering, required this.onTap}); final Channel channel; final bool selected; final bool playing; final bool buffering; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final subtitle = [channel.city, channel.callsign].where((value) => value.isNotEmpty).join(' · '); return Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [StationArtwork(channel: channel, size: 74, borderRadius: 18), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.circle, size: 8, color: Colors.redAccent), SizedBox(width: 7), Text('EN VIVO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 10))]), const SizedBox(height: 7), Text(channel.frequency, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 11))])), const SizedBox(width: 8), AnimatedContainer(duration: const Duration(milliseconds: 180), width: 52, height: 52, decoration: BoxDecoration(color: selected ? Colors.white : AppTheme.orange, shape: BoxShape.circle), alignment: Alignment.center, child: buffering ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black)) : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 31))]))))); }
}

class _SectionTitle extends StatelessWidget { const _SectionTitle({required this.title}); final String title; @override Widget build(BuildContext context) => Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, letterSpacing: 2.2, fontSize: 11, fontWeight: FontWeight.w800)); }

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.onParticipate, required this.onLatest, required this.onPromotions}); final VoidCallback onParticipate; final VoidCallback onLatest; final VoidCallback onPromotions;
  @override Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35, children: [_ExploreCard(icon: Icons.mic_rounded, title: 'Participa', subtitle: 'Pide una canción', onTap: onParticipate), _ExploreCard(icon: Icons.local_fire_department_rounded, title: 'Lo último', subtitle: 'Contenido reciente', onTap: onLatest), _ExploreCard(icon: Icons.card_giftcard_rounded, title: 'Promociones', subtitle: 'Próximamente', onTap: onPromotions), const _ExploreCard(icon: Icons.calendar_month_rounded, title: 'Programación', subtitle: 'Próximamente')]);
}

class _ExploreCard extends StatelessWidget { const _ExploreCard({required this.icon, required this.title, required this.subtitle, this.onTap}); final IconData icon; final String title; final String subtitle; final VoidCallback? onTap; @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppTheme.orange), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11))])))); }

class _ApiError extends StatelessWidget { const _ApiError({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 36), const SizedBox(height: 10), const Text('No pudimos cargar las estaciones.', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Reintentar'))]))); }
class _EmptyChannels extends StatelessWidget { const _EmptyChannels(); @override Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aún no hay canales publicados.'))); }

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.channel, required this.isPlaying, required this.isBuffering, required this.errorMessage, required this.onTap, required this.onToggle, required this.onClose}); final Channel channel; final bool isPlaying; final bool isBuffering; final String? errorMessage; final VoidCallback onTap; final Future<void> Function() onToggle; final Future<void> Function() onClose;
  @override Widget build(BuildContext context) => Material(color: const Color(0xFF151515), child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.fromLTRB(14, 9, 8, 9), child: Row(children: [StationArtwork(channel: channel, size: 42, borderRadius: 10), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(channel.frequency, style: const TextStyle(fontWeight: FontWeight.w900)), Text(errorMessage ?? (isPlaying ? 'En vivo' : 'Pausado'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: errorMessage == null ? Colors.white54 : Colors.redAccent, fontSize: 10))])), IconButton(onPressed: () => onToggle(), icon: isBuffering ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)), IconButton(onPressed: () => onClose(), icon: const Icon(Icons.close_rounded, size: 20))]))));
}

class _NowPlayingSheet extends StatelessWidget {
  const _NowPlayingSheet({required this.channel, required this.channels, required this.isPlaying, required this.isBuffering, required this.onToggle, required this.onSelectChannel}); final Channel channel; final List<Channel> channels; final bool isPlaying; final bool isBuffering; final Future<void> Function() onToggle; final Future<void> Function(Channel) onSelectChannel;
  @override Widget build(BuildContext context) => Container(padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.paddingOf(context).bottom + 24), decoration: const BoxDecoration(color: Color(0xFF111111), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99))), const SizedBox(height: 22), StationArtwork(channel: channel, size: 160, borderRadius: 28), const SizedBox(height: 18), Text(channel.frequency, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), Text(channel.city, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 20), FilledButton.tonalIcon(onPressed: isBuffering ? null : () => onToggle(), icon: isBuffering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(isPlaying ? 'Pausar' : 'Escuchar en vivo')), if (channels.length > 1) ...[const SizedBox(height: 20), const Align(alignment: Alignment.centerLeft, child: Text('Cambiar estación', style: TextStyle(fontWeight: FontWeight.w800))), const SizedBox(height: 8), ...channels.where((item) => item.slug != channel.slug).map((item) => ListTile(contentPadding: EdgeInsets.zero, leading: StationArtwork(channel: item, size: 44, borderRadius: 10), title: Text(item.frequency), subtitle: Text(item.city), trailing: const Icon(Icons.play_arrow_rounded), onTap: () => onSelectChannel(item)))]]));
}

class _ParticipatePage extends StatelessWidget { const _ParticipatePage(); @override Widget build(BuildContext context) => SafeArea(child: SongRequestPage(apiClient: RadioApiClient())); }
