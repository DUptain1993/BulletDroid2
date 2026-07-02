/// Coerce a dynamic JSON value into a String, tolerating producers that
/// serialize the field as a number, bool, etc. instead of a string.
String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Coerce a dynamic JSON value into an int, tolerating numeric strings.
int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Coerce a dynamic JSON value into a bool.
bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Coerce a dynamic JSON value into a List<String>, stringifying any
/// non-string elements rather than throwing.
List<String> _asStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => _asString(e)).toList();
}

/// Coerce a dynamic JSON value into a Map<String, dynamic>, or null if it
/// isn't map-shaped.
Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Represents the complete settings for a LunaLib config
class ConfigSettings {
  // General settings
  String name = '';
  String author = '';
  String version = '';
  int suggestedBots = 1;
  int maxCPM = 0;
  DateTime? lastModified;
  String additionalInfo = '';
  List<String> requiredPlugins = [];
  bool saveEmptyCaptures = false;
  bool continueOnCustom = false;
  bool saveHitsToTextFile = false;

  // Request settings
  bool ignoreResponseErrors = false;
  int maxRedirects = 8;
  int timeoutMs = 30000;

  // Proxy settings
  bool needsProxies = false;
  bool onlySocks = false;
  bool onlySsl = false;
  int maxProxyUses = 0;
  bool banProxyAfterGoodStatus = false;
  int banLoopEvasionOverride = -1;

  // Data settings
  bool encodeData = false;
  String allowedWordlist1 = '';
  String allowedWordlist2 = '';
  List<DataRule> dataRules = [];

  // Custom inputs
  List<CustomInput> customInputs = [];

  // Selenium settings
  bool forceHeadless = false;
  bool alwaysOpen = false;
  bool alwaysQuit = false;
  bool quitOnBanRetry = false;
  bool disableNotifications = false;
  String customUserAgent = '';
  bool randomUA = false;
  String customCMDArgs = '';

  ConfigSettings();

  /// Create ConfigSettings from OpenBullet Legacy JSON
  ///
  /// Values are coerced defensively instead of cast, and each section is
  /// wrapped independently so a single malformed/mistyped field (e.g. a
  /// number where a string was expected) can't abort the whole parse.
  factory ConfigSettings.fromLegacyJson(Map<String, dynamic> json) {
    final settings = ConfigSettings();

    try {
      // General settings
      settings.name = _asString(json['Name']);
      settings.author = _asString(json['Author']);
      settings.version = _asString(json['Version']);
      settings.suggestedBots = _asInt(json['SuggestedBots'], 1);
      settings.maxCPM = _asInt(json['MaxCPM']);
      settings.additionalInfo = _asString(json['AdditionalInfo']);
      settings.saveEmptyCaptures = _asBool(json['SaveEmptyCaptures']);
      settings.continueOnCustom = _asBool(json['ContinueOnCustom']);
      settings.saveHitsToTextFile = _asBool(json['SaveHitsToTextFile']);

      if (json['LastModified'] != null) {
        try {
          settings.lastModified = DateTime.parse(_asString(json['LastModified']));
        } catch (e) {
          // Ignore error
        }
      }

      settings.requiredPlugins = _asStringList(json['RequiredPlugins']);
    } catch (e) {
      // Ignore malformed general fields
    }

    try {
      // Request settings
      settings.ignoreResponseErrors = _asBool(json['IgnoreResponseErrors']);
      settings.maxRedirects = _asInt(json['MaxRedirects'], 8);

      // Proxy settings
      settings.needsProxies = _asBool(json['NeedsProxies']);
      settings.onlySocks = _asBool(json['OnlySocks']);
      settings.onlySsl = _asBool(json['OnlySsl']);
      settings.maxProxyUses = _asInt(json['MaxProxyUses']);
      settings.banProxyAfterGoodStatus = _asBool(
        json['BanProxyAfterGoodStatus'],
      );
      settings.banLoopEvasionOverride = _asInt(
        json['BanLoopEvasionOverride'],
        -1,
      );
    } catch (e) {
      // Ignore malformed request/proxy fields
    }

    try {
      // Data settings
      settings.encodeData = _asBool(json['EncodeData']);
      settings.allowedWordlist1 = _asString(json['AllowedWordlist1']);
      settings.allowedWordlist2 = _asString(json['AllowedWordlist2']);

      if (json['DataRules'] is List) {
        final dataRules = <DataRule>[];
        for (final rule in json['DataRules'] as List) {
          try {
            final ruleMap = _asMap(rule);
            if (ruleMap != null) dataRules.add(DataRule.fromJson(ruleMap));
          } catch (e) {
            // Skip malformed data rule entries
          }
        }
        settings.dataRules = dataRules;
      }
    } catch (e) {
      // Ignore malformed data settings fields
    }

    try {
      // Custom inputs
      if (json['CustomInputs'] is List) {
        final customInputs = <CustomInput>[];
        for (final input in json['CustomInputs'] as List) {
          try {
            final inputMap = _asMap(input);
            if (inputMap != null) {
              customInputs.add(CustomInput.fromJson(inputMap));
            }
          } catch (e) {
            // Skip malformed custom input entries
          }
        }
        settings.customInputs = customInputs;
      }
    } catch (e) {
      // Ignore malformed custom inputs
    }

    try {
      // Selenium settings
      settings.forceHeadless = _asBool(json['ForceHeadless']);
      settings.alwaysOpen = _asBool(json['AlwaysOpen']);
      settings.alwaysQuit = _asBool(json['AlwaysQuit']);
      settings.quitOnBanRetry = _asBool(json['QuitOnBanRetry']);
      settings.disableNotifications = _asBool(json['DisableNotifications']);
      settings.customUserAgent = _asString(json['CustomUserAgent']);
      settings.randomUA = _asBool(json['RandomUA']);
      settings.customCMDArgs = _asString(json['CustomCMDArgs']);
    } catch (e) {
      // Ignore malformed selenium fields
    }

    return settings;
  }

  /// Create ConfigSettings from an OpenBullet 2 `settings.json` (nested format)
  /// plus its accompanying `metadata.json`, as found inside an .opk package.
  ///
  /// Real-world .opk files are not guaranteed to match RuriLib's shape
  /// exactly (hand-edited files, tools that mis-serialize fields, etc.), so
  /// every value is coerced defensively instead of cast, and each section is
  /// parsed independently so a single malformed field can't blow up the
  /// whole config load.
  factory ConfigSettings.fromOpenBullet2Json(
    Map<String, dynamic> settingsJson, {
    Map<String, dynamic>? metadataJson,
  }) {
    final settings = ConfigSettings();

    if (metadataJson != null) {
      try {
        settings.name = _asString(metadataJson['Name']);
        settings.author = _asString(metadataJson['Author']);
        if (metadataJson['LastModified'] != null) {
          try {
            settings.lastModified = DateTime.parse(
              _asString(metadataJson['LastModified']),
            );
          } catch (e) {
            // Ignore error
          }
        }
        settings.requiredPlugins = _asStringList(metadataJson['Plugins']);
      } catch (e) {
        // Ignore malformed metadata.json fields
      }
    }

    final general = _asMap(settingsJson['GeneralSettings']);
    if (general != null) {
      try {
        settings.suggestedBots = _asInt(general['SuggestedBots'], 1);
        settings.maxCPM = _asInt(general['MaximumCPM']);
        settings.saveEmptyCaptures = _asBool(general['SaveEmptyCaptures']);
        final continueStatuses = _asStringList(general['ContinueStatuses']);
        settings.continueOnCustom = continueStatuses.any(
          (status) => status.toUpperCase() == 'CUSTOM',
        );
      } catch (e) {
        // Ignore malformed GeneralSettings fields
      }
    }

    final proxy = _asMap(settingsJson['ProxySettings']);
    if (proxy != null) {
      try {
        settings.needsProxies = _asBool(proxy['UseProxies']);
        settings.maxProxyUses = _asInt(proxy['MaxUsesPerProxy']);
        settings.banLoopEvasionOverride = _asInt(
          proxy['BanLoopEvasion'],
          -1,
        );
        final allowedTypes = _asStringList(
          proxy['AllowedProxyTypes'],
        ).map((t) => t.toUpperCase());
        settings.onlySocks =
            allowedTypes.isNotEmpty &&
            !allowedTypes.any((t) => t == 'HTTP' || t == 'HTTPS');
      } catch (e) {
        // Ignore malformed ProxySettings fields
      }
    }

    final data = _asMap(settingsJson['DataSettings']);
    if (data != null) {
      try {
        settings.encodeData = _asBool(data['UrlEncodeDataAfterSlicing']);
        final allowedWordlists = _asStringList(data['AllowedWordlistTypes']);
        if (allowedWordlists.isNotEmpty) {
          settings.allowedWordlist1 = allowedWordlists[0];
        }
        if (allowedWordlists.length > 1) {
          settings.allowedWordlist2 = allowedWordlists[1];
        }
      } catch (e) {
        // Ignore malformed DataSettings fields
      }
    }

    final input = _asMap(settingsJson['InputSettings']);
    if (input != null && input['CustomInputs'] is List) {
      final customInputs = <CustomInput>[];
      for (final entry in input['CustomInputs'] as List) {
        try {
          final entryMap = _asMap(entry);
          if (entryMap == null) continue;
          customInputs.add(
            CustomInput(
              variableName: _asString(entryMap['VariableName']),
              description: _asString(entryMap['Description']),
              value: _asString(entryMap['DefaultAnswer']),
            ),
          );
        } catch (e) {
          // Skip malformed custom input entries
        }
      }
      settings.customInputs = customInputs;
    }

    return settings;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Author': author,
      'Version': version,
      'SuggestedBots': suggestedBots,
      'MaxCPM': maxCPM,
      'LastModified': lastModified?.toIso8601String(),
      'AdditionalInfo': additionalInfo,
      'RequiredPlugins': requiredPlugins,
      'SaveEmptyCaptures': saveEmptyCaptures,
      'ContinueOnCustom': continueOnCustom,
      'SaveHitsToTextFile': saveHitsToTextFile,
      'IgnoreResponseErrors': ignoreResponseErrors,
      'MaxRedirects': maxRedirects,
      'NeedsProxies': needsProxies,
      'OnlySocks': onlySocks,
      'OnlySsl': onlySsl,
      'MaxProxyUses': maxProxyUses,
      'BanProxyAfterGoodStatus': banProxyAfterGoodStatus,
      'BanLoopEvasionOverride': banLoopEvasionOverride,
      'EncodeData': encodeData,
      'AllowedWordlist1': allowedWordlist1,
      'AllowedWordlist2': allowedWordlist2,
      'DataRules': dataRules.map((rule) => rule.toJson()).toList(),
      'CustomInputs': customInputs.map((input) => input.toJson()).toList(),
      'ForceHeadless': forceHeadless,
      'AlwaysOpen': alwaysOpen,
      'AlwaysQuit': alwaysQuit,
      'QuitOnBanRetry': quitOnBanRetry,
      'DisableNotifications': disableNotifications,
      'CustomUserAgent': customUserAgent,
      'RandomUA': randomUA,
      'CustomCMDArgs': customCMDArgs,
    };
  }

  @override
  String toString() {
    return 'ConfigSettings(name: $name, author: $author, version: $version)';
  }
}

/// Represents a data validation rule
class DataRule {
  String sliceName = '';
  DataRuleType ruleType = DataRuleType.mustContain;
  String ruleString = '';

  DataRule({
    required this.sliceName,
    required this.ruleType,
    required this.ruleString,
  });

  factory DataRule.fromJson(Map<String, dynamic> json) {
    return DataRule(
      sliceName: json['SliceName'] ?? '',
      ruleType: DataRuleType.values.firstWhere(
        (type) => type.index == (json['RuleType'] ?? 0),
        orElse: () => DataRuleType.mustContain,
      ),
      ruleString: json['RuleString'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SliceName': sliceName,
      'RuleType': ruleType.index,
      'RuleString': ruleString,
    };
  }

  /// Validate a value against this rule
  bool validate(String value) {
    switch (ruleType) {
      case DataRuleType.mustContain:
        return _checkMustContain(value);
      case DataRuleType.mustNotContain:
        return !_checkMustContain(value);
      case DataRuleType.minLength:
        final minLength = int.tryParse(ruleString) ?? 0;
        return value.length >= minLength;
      case DataRuleType.maxLength:
        final maxLength = int.tryParse(ruleString) ?? 0;
        return value.length <= maxLength;
      case DataRuleType.mustMatchRegex:
        try {
          final regex = RegExp(ruleString);
          return regex.hasMatch(value);
        } catch (e) {
          return false;
        }
    }
  }

  bool _checkMustContain(String value) {
    switch (ruleString.toLowerCase()) {
      case 'lowercase':
        return value.contains(RegExp(r'[a-z]'));
      case 'uppercase':
        return value.contains(RegExp(r'[A-Z]'));
      case 'digit':
        return value.contains(RegExp(r'\d'));
      case 'symbol':
        return value.contains(RegExp(r'[@$!%*#?&]'));
      default:
        return value.contains(ruleString);
    }
  }

  @override
  String toString() {
    return 'DataRule(slice: $sliceName, type: $ruleType, rule: $ruleString)';
  }
}

/// Types of data validation rules
enum DataRuleType {
  mustContain,
  mustNotContain,
  minLength,
  maxLength,
  mustMatchRegex,
}

/// Represents a custom input variable
class CustomInput {
  String variableName = '';
  String description = '';
  String value = '';
  bool isRequired = true;

  CustomInput({
    required this.variableName,
    required this.description,
    this.value = '',
    this.isRequired = true,
  });

  factory CustomInput.fromJson(Map<String, dynamic> json) {
    return CustomInput(
      variableName: json['VariableName'] ?? '',
      description: json['Description'] ?? '',
      value: json['Value'] ?? '',
      isRequired: json['IsRequired'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VariableName': variableName,
      'Description': description,
      'Value': value,
      'IsRequired': isRequired,
    };
  }

  @override
  String toString() {
    return 'CustomInput(var: $variableName, desc: $description, value: $value, required: $isRequired)';
  }
}
