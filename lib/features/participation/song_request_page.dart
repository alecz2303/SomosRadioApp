import 'package:flutter/material.dart';

import '../../core/api/radio_api_client.dart';
import '../../core/models/channel.dart';
import '../../core/theme/app_theme.dart';

class SongRequestPage extends StatefulWidget {
  const SongRequestPage({super.key});

  @override
  State<SongRequestPage> createState() => _SongRequestPageState();
}

class _SongRequestPageState extends State<SongRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = RadioApiClient();
  final _nameController = TextEditingController();
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  final _dedicationController = TextEditingController();

  late Future<List<Channel>> _channelsFuture;
  Channel? _selectedChannel;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _channelsFuture = _apiClient.fetchSomosRadioChannels();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _songController.dispose();
    _artistController.dispose();
    _dedicationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final channel = _selectedChannel;
    if (channel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una estación.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await _apiClient.submitSongRequest(
        channelSlug: channel.slug,
        listenerName: _nameController.text,
        song: _songController.text,
        artist: _artistController.text,
        dedication: _dedicationController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.orange,
            size: 54,
          ),
          title: const Text('¡Solicitud enviada!'),
          content: Text(
            '${result.message}\n\n${channel.displayName}${channel.city.isNotEmpty ? ' · ${channel.city}' : ''}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Listo'),
            ),
          ],
        ),
      );

      _songController.clear();
      _artistController.clear();
      _dedicationController.clear();
    } on RadioApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No fue posible enviar la solicitud. Intenta nuevamente.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Escribe $label.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pide tu canción')),
      body: SafeArea(
        child: FutureBuilder<List<Channel>>(
          future: _channelsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _LoadError(
                onRetry: () {
                  setState(() {
                    _channelsFuture = _apiClient.fetchSomosRadioChannels();
                  });
                },
              );
            }

            final channels = snapshot.data ?? const <Channel>[];
            if (channels.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay estaciones disponibles en este momento.'),
                ),
              );
            }

            _selectedChannel ??= channels.first;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.orange.withValues(alpha: .35),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.orange,
                          size: 46,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '¿Qué quieres escuchar?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Manda tu canción y una dedicatoria directamente a Somos Radio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Channel>(
                    value: _selectedChannel,
                    decoration: const InputDecoration(
                      labelText: 'Estación',
                      prefixIcon: Icon(Icons.radio_rounded),
                    ),
                    items: channels
                        .map(
                          (channel) => DropdownMenuItem(
                            value: channel,
                            child: Text(
                              '${channel.frequency}${channel.city.isNotEmpty ? ' · ${channel.city}' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (channel) => setState(() => _selectedChannel = channel),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) => _required(value, 'tu nombre'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _songController,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Canción',
                      prefixIcon: Icon(Icons.audiotrack_rounded),
                    ),
                    validator: (value) => _required(value, 'la canción'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _artistController,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Artista',
                      prefixIcon: Icon(Icons.mic_external_on_rounded),
                    ),
                    validator: (value) => _required(value, 'el artista'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dedicationController,
                    maxLength: 1000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Dedicatoria (opcional)',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 72),
                        child: Icon(Icons.favorite_rounded),
                      ),
                      hintText: 'Ej. Para Mariana, que va saliendo del trabajo…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting ? 'Enviando…' : 'Enviar solicitud',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'La solicitud se envía al panel de administración de la estación. Su reproducción queda sujeta a la programación y criterio editorial de Somos Radio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 44),
            const SizedBox(height: 12),
            const Text(
              'No pudimos cargar las estaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
