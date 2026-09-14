import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import 'song_request_form_page.dart';

class SongRequestPage extends StatelessWidget {
  const SongRequestPage({super.key});

  Future<void> _openWhatsApp(
    BuildContext context,
    String number,
    String station,
  ) async {
    final text = Uri.encodeComponent(
      'Hola Somos Radio, les escribo desde la app. Estoy escuchando $station.',
    );
    final uri = Uri.parse('https://wa.me/$number?text=$text');

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir WhatsApp.')),
      );
    }
  }

  void _openSongRequest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SongRequestFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participa')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.orange.withValues(alpha: .30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.forum_rounded, color: AppTheme.orange, size: 52),
                  SizedBox(height: 14),
                  Text(
                    'Tu voz también es parte de Somos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Elige cómo quieres participar con Somos Radio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _ParticipationCard(
              icon: Icons.music_note_rounded,
              title: 'Pide tu canción',
              subtitle: 'Envía tu canción y dedicatoria desde la app',
              onTap: () => _openSongRequest(context),
            ),
            const SizedBox(height: 12),
            _ParticipationCard(
              icon: Icons.chat_rounded,
              title: 'WhatsApp · 89.1 FM',
              subtitle: 'Tuxtla Gutiérrez · +52 961 119 3641',
              onTap: () => _openWhatsApp(
                context,
                '529611193641',
                'Somos Radio 89.1 FM',
              ),
            ),
            const SizedBox(height: 12),
            _ParticipationCard(
              icon: Icons.chat_rounded,
              title: 'WhatsApp · 102.9 FM',
              subtitle: 'San Cristóbal de las Casas · +52 967 678 2403',
              onTap: () => _openWhatsApp(
                context,
                '529676782403',
                'Somos Radio 102.9 FM',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MÁS FORMAS DE PARTICIPAR',
              style: TextStyle(
                color: Colors.white38,
                letterSpacing: 2.1,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const _FutureFeature(
              icon: Icons.emoji_events_rounded,
              title: 'Concursos y dinámicas',
              text: 'Próximamente',
            ),
            const SizedBox(height: 10),
            const _FutureFeature(
              icon: Icons.poll_rounded,
              title: 'Encuestas',
              text: 'Próximamente',
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

class _ParticipationCard extends StatelessWidget {
  const _ParticipationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                child: Icon(icon, color: AppTheme.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
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
    return Container(
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
