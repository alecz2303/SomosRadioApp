class AppConfig {
  const AppConfig._();

  static const stationSlug = 'somos-radio';

  /// Configurable al compilar:
  /// flutter run --dart-define=RADIO_API_BASE_URL=https://tu-api.com/api/v1
  static const radioApiBaseUrl = String.fromEnvironment(
    'RADIO_API_BASE_URL',
    defaultValue: '',
  );

  static const isConceptDemo = true;
}
