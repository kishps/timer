import 'dart:io';

bool isMobilePlatform() => Platform.isAndroid || Platform.isIOS;

Future<void> writeStringToFile(String path, String contents) async {
  final file = File(path);
  await file.writeAsString(contents);
}

Future<String> readStringFromFile(String path) async {
  final file = File(path);
  return file.readAsString();
}

