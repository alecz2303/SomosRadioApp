import 'package:flutter/material.dart';

import '../audio/radio_player_controller.dart';
import '../theme/app_theme.dart';
import 'station_artwork.dart';

class PersistentNowPlayingShell extends StatefulWidget {
  const PersistentNowPlayingShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<PersistentNowPlayingShell> createState() =>
      _PersistentNowPlayingShellState();
}

class _PersistentNowPlayingShellState extends State<PersistentNowPlayingShell> {
  late final RadioPlayerController _radioPlayer;

  @override
  void initState() {
    super.initState();
    _radioPlayer = RadioPlayerController()..addListener(_onPlayerChanged);
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

  @override
  Widget build(BuildContext context) {
    final channel = _radioPlayer.currentChannel;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: channel == null
          ? null
          : SafeArea(
              top: false,
              child: Material(
                color: const Color(0xFF111111),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x22FFFFFF)),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Row(
                    children: [
                      StationArtwork(
                        channel: channel,
                        size: 48,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTÁS ESCUCHANDO',
                              style: TextStyle(
                                color: AppTheme.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              channel.frequency,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (channel.city.isNotEmpty)
                              Text(
                                channel.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_radioPlayer.isBuffering)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTheme.orange,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: _radioPlayer.isPlaying ? 'Pausar' : 'Reproducir',
                          onPressed: _radioPlayer.toggle,
                          icon: Icon(
                            _radioPlayer.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppTheme.orange,
                            size: 36,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Detener',
                        onPressed: _radioPlayer.stop,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
