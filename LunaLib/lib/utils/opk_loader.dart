import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../core/config.dart';
import '../core/config_settings.dart';
import '../parsing/loli_parser.dart';
import '../services/file_system_service.dart';

/// Loads OpenBullet 2 `.opk` config packages (zip archives containing
/// `metadata.json`, `settings.json` and a script entry) and adapts them
/// into the [Config] model used by the rest of LunaLib.
///
/// Reference: RuriLib.Helpers.ConfigPacker in the OpenBullet2 source, which
/// packs an .opk as: readme.md, metadata.json, settings.json and one of
/// script.loli / script.legacy / script.cs / build.dll depending on the
/// config's mode.
class OpkLoader {
  static const _scriptEntryNames = ['script.loli', 'script.legacy'];

  /// Load and parse a `.opk` file from disk.
  static Future<Config> loadFromFile(String filePath) async {
    final bytes = await fileSystemService.readFileBytes(filePath);
    return loadFromBytes(bytes);
  }

  /// Whether the given path looks like an .opk package.
  static bool isOpkFile(String filePath) =>
      filePath.toLowerCase().endsWith('.opk');

  /// Whether the given bytes look like a zip archive (opk packages are
  /// zip files, regardless of what extension the user gave them).
  static bool looksLikeZip(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);

  /// Parse a `.opk` package already loaded into memory.
  static Config loadFromBytes(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw FormatException('Not a valid .opk (zip) archive: $e');
    }

    final metadataEntry = _findEntry(archive, 'metadata.json');
    final settingsEntry = _findEntry(archive, 'settings.json');

    Map<String, dynamic>? metadataJson;
    if (metadataEntry != null) {
      try {
        metadataJson =
            jsonDecode(_readText(metadataEntry)) as Map<String, dynamic>;
      } catch (e) {
        throw FormatException('Failed to parse metadata.json: $e');
      }
    }

    Map<String, dynamic>? settingsJson;
    if (settingsEntry != null) {
      try {
        settingsJson =
            jsonDecode(_readText(settingsEntry)) as Map<String, dynamic>;
      } catch (e) {
        throw FormatException('Failed to parse settings.json: $e');
      }
    }

    if (_findEntry(archive, 'script.cs') != null) {
      throw FormatException(
        'This .opk uses a C# script and is not supported. '
        'Only LoliCode/legacy LoliScript configs can be run.',
      );
    }
    if (_findEntry(archive, 'build.dll') != null) {
      throw FormatException(
        'This .opk uses a compiled DLL script and is not supported.',
      );
    }

    ArchiveFile? scriptEntry;
    for (final name in _scriptEntryNames) {
      scriptEntry = _findEntry(archive, name);
      if (scriptEntry != null) break;
    }

    if (scriptEntry == null) {
      throw FormatException(
        'Could not find a script.loli or script.legacy entry in the .opk package.',
      );
    }

    final scriptContent = _readText(scriptEntry);
    final parsed = LoliParser.parseConfig(scriptContent);

    ConfigSettings settings;
    if (settingsJson != null && settingsJson.containsKey('GeneralSettings')) {
      settings = ConfigSettings.fromOpenBullet2Json(
        settingsJson,
        metadataJson: metadataJson,
      );
    } else if (settingsJson != null) {
      // Fall back to the flat OpenBullet-legacy shape, in case this
      // package was re-saved by this app rather than a genuine OB2 export.
      settings = ConfigSettings.fromLegacyJson(settingsJson);
    } else {
      settings = ConfigSettings();
    }

    final readmeEntry = _findEntry(archive, 'readme.md');
    final description = readmeEntry != null ? _readText(readmeEntry) : '';
    if (settings.additionalInfo.isEmpty && description.isNotEmpty) {
      settings.additionalInfo = description;
    }

    final metadataName = _stringOrNull(metadataJson?['Name']);
    final name = (metadataName != null && metadataName.isNotEmpty)
        ? metadataName
        : (settings.name.isNotEmpty ? settings.name : 'Imported Config');

    final metadataAuthor = _stringOrNull(metadataJson?['Author']);
    final author = (metadataAuthor != null && metadataAuthor.isNotEmpty)
        ? metadataAuthor
        : settings.author;

    final category = _stringOrNull(metadataJson?['Category']) ?? 'OpenBullet2';

    final metadata = ConfigMetadata(
      name: name,
      author: author,
      category: category,
      description: description,
      version: settings.version.isNotEmpty ? settings.version : '2.0.0',
    );

    return Config(
      metadata: metadata,
      blocks: parsed.blocks,
      settings: settings,
    );
  }

  /// Rewrite the script entry inside an existing .opk archive, preserving
  /// every other entry (metadata.json, settings.json, readme.md, ...).
  static Uint8List rewriteScript(Uint8List originalBytes, String newScript) {
    return _rewriteEntry(originalBytes, _scriptEntryNames, newScript);
  }

  /// Rewrite the settings.json entry inside an existing .opk archive,
  /// preserving every other entry.
  static Uint8List rewriteSettings(
    Uint8List originalBytes,
    Map<String, dynamic> newSettingsJson,
  ) {
    final content = JsonEncoder.withIndent('  ').convert(newSettingsJson);
    return _rewriteEntry(originalBytes, const ['settings.json'], content);
  }

  static Uint8List _rewriteEntry(
    Uint8List originalBytes,
    List<String> candidateNames,
    String newContent,
  ) {
    final archive = ZipDecoder().decodeBytes(originalBytes);

    String targetName = candidateNames.first;
    for (final name in candidateNames) {
      if (_findEntry(archive, name) != null) {
        targetName = name;
        break;
      }
    }

    final rebuilt = Archive();
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (candidateNames.contains(file.name.toLowerCase())) {
        continue;
      }
      final data = _bytesOf(file);
      rebuilt.addFile(ArchiveFile(file.name, data.length, data));
    }

    final newBytes = utf8.encode(newContent);
    rebuilt.addFile(ArchiveFile(targetName, newBytes.length, newBytes));

    final encoded = ZipEncoder().encode(rebuilt);
    if (encoded == null) {
      throw StateError('Failed to re-encode .opk archive');
    }
    return Uint8List.fromList(encoded);
  }

  static ArchiveFile? _findEntry(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.isFile && file.name.toLowerCase() == name) {
        return file;
      }
    }
    return null;
  }

  static Uint8List _bytesOf(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) return content;
    return Uint8List.fromList(List<int>.from(content as List));
  }

  static String _readText(ArchiveFile file) => utf8.decode(_bytesOf(file));

  /// Coerce a dynamic JSON value into a String, tolerating producers that
  /// serialize the field as a number, bool, etc. instead of a string.
  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
