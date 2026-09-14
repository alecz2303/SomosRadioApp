import 'package:flutter/material.dart';

import '../audio/radio_player_controller.dart';
import '../theme/app_theme.dart';
import 'station_artwork.dart';

class PersistentAudioBar extends StatefulWidget {
  const PersistentAudioBar({required this.child, super.key});

  final Widget child;

  @override
  State<PersistentAudioBar> createState() => _PersistentAudioBarState();
}

class _PersistentAudioBarState extends State<PersistentAudioBar> {
  late final RadioPlayerController _player;

  @override
  void initState() {
    super.initState();
    _player = RadioPlayerController()..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onChanged);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = _player.currentChannel;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: channel == null
          ? null
          : SafeArea(
              top: false,
              child: Material(
                color: const Color(0xFF111111),
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x22FFFFFF)),
                      ),
                    ),
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
                              Text(
                                channel.frequency,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                channel.city.isNotEmpty
                                    ? channel.city
                                    : 'Somos Radio',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_player.isBuffering)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: AppTheme.orange,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _player.toggle,
                            icon: Icon(
                              _player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppTheme.orange,
                              size: 30,
                            ),
                          ),
                        IconButton(
                          onPressed: _player.stop,
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
            ),
    );
  }
}
