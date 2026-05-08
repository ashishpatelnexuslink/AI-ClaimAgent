import 'package:flutter/services.dart';

class AndroidDownloads {
  AndroidDownloads._();

  static const MethodChannel _channel = MethodChannel('claim_ai/downloads');

  /// Copies the file at [srcPath] into the public Downloads collection via
  /// MediaStore. Available on Android 10+ with no runtime permission. Throws
  /// a [PlatformException] with code `UNSUPPORTED` on Android 9 and below.
  static Future<String> saveToDownloads({
    required String srcPath,
    required String fileName,
    required String mimeType,
  }) async {
    final result = await _channel.invokeMethod<String>('saveToDownloads', {
      'srcPath': srcPath,
      'fileName': fileName,
      'mimeType': mimeType,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'EMPTY_RESULT',
        message: 'No URI returned from saveToDownloads',
      );
    }
    return result;
  }
}
