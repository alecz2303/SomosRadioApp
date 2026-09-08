import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 22),
            Container(
              width: 88,
              height: 88,
              margin: const EdgeInsets.symmetric(horizontal: 118),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppTheme.orange,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Promociones y dinámicas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí podrás encontrar promociones, concursos, eventos y beneficios publicados por Somos Radio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 34),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: AppTheme.orange,
                      size: 42,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay promociones activas en este momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mantente pendiente de Somos Radio para próximas dinámicas y promociones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Sin contenido de demostración inventado',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'PREPARADO PARA',
              style: TextStyle(
                color: Colors.white38,
                letterSpacing: 2.2,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const _Capability(
              icon: Icons.image_rounded,
              title: 'Campañas con imagen',
              text: 'Banner, título, descripción y vigencia.',
            ),
            const _Capability(
              icon: Icons.schedule_rounded,
              title: 'Vigencia automática',
              text: 'Mostrar únicamente promociones activas.',
            ),
            const _Capability(
              icon: Icons.radio_rounded,
              title: 'Por estación',
              text: 'Promociones generales o específicas para 89.1 y 102.9 FM.',
            ),
            const _Capability(
              icon: Icons.touch_app_rounded,
              title: 'Llamado a la acción',
              text: 'Botones para participar, registrarse o abrir enlaces oficiales.',
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

class _Capability extends StatelessWidget {
  const _Capability({
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
            Icon(icon, color: AppTheme.orange),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
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
