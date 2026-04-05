String buildMediaUrl(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) return '';
  if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
    return rawPath;
  }
  final base = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5001',
  );
  final clean = rawPath.startsWith('/') ? rawPath : '/$rawPath';
  return '$base$clean';
}
