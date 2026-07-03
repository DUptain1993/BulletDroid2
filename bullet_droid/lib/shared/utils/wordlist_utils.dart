import 'dart:convert';
import 'dart:io';

class WordlistUtils {
  /// Process raw wordlist content into normalized data lines used by runners.
  static List<String> processContent(String content) {
    return content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Read a file and return processed data lines using [processContent].
  ///
  /// Wordlists/combo files (often breach compilations) are frequently not
  /// valid UTF-8. Falls back to Latin-1 (which can decode any byte) instead
  /// of throwing, so a few mojibake lines don't block the whole import.
  static Future<List<String>> readAndProcessFile(File file) async {
    final bytes = await file.readAsBytes();
    late final String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      content = latin1.decode(bytes);
    }
    return processContent(content);
  }
}
