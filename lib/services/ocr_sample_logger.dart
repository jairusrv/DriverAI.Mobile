import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OcrSampleLogger {
  static Future<void> saveSample(
    String provider,
    String text,
  ) async {
    try {
      final dir =
          await getApplicationDocumentsDirectory();

      final file = File(
        '${dir.path}/ocr_samples.txt',
      );

      final timestamp =
          DateTime.now().toIso8601String();

      await file.writeAsString(
        '''

==============================
$timestamp
PROVIDER: $provider
==============================

$text

''',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}