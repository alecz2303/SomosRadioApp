class AppConfig {
  const AppConfig._();

  static const stationSlug = 'somos-radio';

  /// URL pública de radio-api.
  /// Puede sobrescribirse al compilar con:
  /// flutter run --dart-define=RADIO_API_BASE_URL=https://otra-api.com/api/v1
  static const radioApiBaseUrl = String.fromEnvironment(
    'RADIO_API_BASE_URL',
    defaultValue: 'https://radio-api.djira.xyz/api/v1',
  );

  static const isConceptDemo = true;
}
