import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servizio OCR on-device basato su Google ML Kit.
/// Non richiede internet, nessun costo server, funziona offline al 100%.
abstract final class OcrService {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Estrae i token di testo significativi da un'immagine.
  /// Filtra righe troppo corte o troppo lunghe, restituisce max 10 token.
  static Future<List<String>> extractTokens(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);

      final tokens = <String>{};
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          // Filtra token troppo corti, troppo lunghi o solo spazi
          if (text.length >= 3 && text.length <= 50) {
            tokens.add(text);
          }
        }
      }

      // Prioritizza token che sembrano codici prodotto (contengono cifre o trattini)
      final sorted = tokens.toList()
        ..sort((a, b) {
          final aIsCode = RegExp(r'[0-9\-]').hasMatch(a) ? 0 : 1;
          final bIsCode = RegExp(r'[0-9\-]').hasMatch(b) ? 0 : 1;
          return aIsCode.compareTo(bIsCode);
        });

      return sorted.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  static void close() {
    _recognizer.close();
  }
}
