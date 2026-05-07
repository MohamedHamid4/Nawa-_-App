import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../errors/failures.dart';
import '../errors/result.dart';
import '../utils/app_logger.dart';

class OcrService {
  TextRecognizer? _latin;
  TextRecognizer? _arabic;

  TextRecognizer _recognizerFor(String localeCode) {
    if (localeCode.startsWith('ar')) {
      _arabic ??= TextRecognizer(script: TextRecognitionScript.latin);
      return _arabic!;
    }
    _latin ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _latin!;
  }

  Future<Result<String>> extractText(String imagePath, {String locale = 'en'}) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognizer = _recognizerFor(locale);
      final result = await recognizer.processImage(input);
      return Success(result.text);
    } catch (e, st) {
      AppLogger.e('OCR failed', e, st);
      return FailureResult(ServerFailure(cause: e));
    }
  }

  Future<void> dispose() async {
    await _latin?.close();
    await _arabic?.close();
  }
}
