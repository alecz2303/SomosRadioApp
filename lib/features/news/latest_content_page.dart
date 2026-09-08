import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import 'latest_content_service.dart';

class LatestContentPage extends StatefulWidget {
  const LatestContentPage({super.key});

  @override
  State<LatestContentPage> createState() => _LatestContentPageState();
}

class _LatestContentPageState extends State<LatestContentPage> {
  final LatestContentService _service = const LatestContentService();
  late Future<List<LatestContentItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = _service.fetchLatest();
  }

  void _reload() {
    setState(() {
      _items = _service.fetchLatest();
    });
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir la publicación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lo último')),
      body: SafeArea(
        child: FutureBuilder<List<LatestContentItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(onRetry: _reload);
            }

            final items = snapshot.data ?? const <LatestContentItem>[];
            if (items.isEmpty) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final next = _service.fetchLatest();
                setState(() => _items = next);
                await next;
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: items.length + (AppConfig.isConceptDemo ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Contenido obtenido del sitio oficial de Somos Radio',
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ),
                    );
                  }

                  final item = items[index];
                  return _LatestCard(
                    item: item,
                    onTap: () => _open(context, item.link),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.item, required this.onTap});

  final LatestContentItem item;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.article_rounded, color: AppTheme.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.publishedAt != null) ...[
                      Text(
                        _formatDate(item.publishedAt!),
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Text('Ver publicación', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
                        SizedBox(width: 5),
                        Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white38),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 48),
            const SizedBox(height: 14),
            const Text('No pudimos cargar lo último de Somos Radio.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'El contenido se obtiene directamente de su sitio oficial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Por ahora no hay publicaciones disponibles en el feed de Somos Radio.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
