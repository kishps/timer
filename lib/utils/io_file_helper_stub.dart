bool isMobilePlatform() => false;

Future<void> writeStringToFile(String path, String contents) async {
  throw UnsupportedError('File IO is not available on web.');
}

Future<String> readStringFromFile(String path) async {
  throw UnsupportedError('File IO is not available on web.');
}

