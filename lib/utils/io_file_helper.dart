// Условный экспорт: на web подключаем stub, на остальных платформах — dart:io.
export 'io_file_helper_io.dart' if (dart.library.html) 'io_file_helper_stub.dart';

