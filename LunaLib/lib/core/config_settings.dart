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
  factory ConfigSettings.fromLegacyJson(Map<String, dynamic> json) {
    final settings = ConfigSettings();

    // General settings
    settings.name = json['Name'] ?? '';
    settings.author = json['Author'] ?? '';
    settings.version = json['Version'] ?? '';
    settings.suggestedBots = json['SuggestedBots'] ?? 1;
    settings.maxCPM = json['MaxCPM'] ?? 0;
    settings.additionalInfo = json['AdditionalInfo'] ?? '';
    settings.saveEmptyCaptures = json['SaveEmptyCaptures'] ?? false;
    settings.continueOnCustom = json['ContinueOnCustom'] ?? false;
    settings.saveHitsToTextFile = json['SaveHitsToTextFile'] ?? false;

    if (json['LastModified'] != null) {
      try {
        settings.lastModified = DateTime.parse(json['LastModified']);
      } catch (e) {
        // Ignore error
      }
    }

    if (json['RequiredPlugins'] != null) {
      settings.requiredPlugins = List<String>.from(json['RequiredPlugins']);
    }

    // Request settings
    settings.ignoreResponseErrors = json['IgnoreResponseErrors'] ?? false;
    settings.maxRedirects = json['MaxRedirects'] ?? 8;

    // Proxy settings
    settings.needsProxies = json['NeedsProxies'] ?? false;
    settings.onlySocks = json['OnlySocks'] ?? false;
    settings.onlySsl = json['OnlySsl'] ?? false;
    settings.maxProxyUses = json['MaxProxyUses'] ?? 0;
    settings.banProxyAfterGoodStatus = json['BanProxyAfterGoodStatus'] ?? false;
    settings.banLoopEvasionOverride = json['BanLoopEvasionOverride'] ?? -1;

    // Data settings
    settings.encodeData = json['EncodeData'] ?? false;
    settings.allowedWordlist1 = json['AllowedWordlist1'] ?? '';
    settings.allowedWordlist2 = json['AllowedWordlist2'] ?? '';

    if (json['DataRules'] != null) {
      settings.dataRules = (json['DataRules'] as List)
          .map((rule) => DataRule.fromJson(rule))
          .toList();
    }

    // Custom inputs
    if (json['CustomInputs'] != null) {
      settings.customInputs = (json['CustomInputs'] as List)
          .map((input) => CustomInput.fromJson(input))
          .toList();
    }

    // Selenium settings
    settings.forceHeadless = json['ForceHeadless'] ?? false;
    settings.alwaysOpen = json['AlwaysOpen'] ?? false;
    settings.alwaysQuit = json['AlwaysQuit'] ?? false;
    settings.quitOnBanRetry = json['QuitOnBanRetry'] ?? false;
    settings.disableNotifications = json['DisableNotifications'] ?? false;
    settings.customUserAgent = json['CustomUserAgent'] ?? '';
    settings.randomUA = json['RandomUA'] ?? false;
    settings.customCMDArgs = json['CustomCMDArgs'] ?? '';

    return settings;
  }

  /// Create ConfigSettings from an OpenBullet 2 `settings.json` (nested format)
  /// plus its accompanying `metadata.json`, as found inside an .opk package.
  factory ConfigSettings.fromOpenBullet2Json(
    Map<String, dynamic> settingsJson, {
    Map<String, dynamic>? metadataJson,
  }) {
    final settings = ConfigSettings();

    if (metadataJson != null) {
      settings.name = metadataJson['Name'] ?? '';
      settings.author = metadataJson['Author'] ?? '';
      if (metadataJson['LastModified'] != null) {
        try {
          settings.lastModified = DateTime.parse(metadataJson['LastModified']);
        } catch (e) {
          // Ignore error
        }
      }
      if (metadataJson['Plugins'] != null) {
        settings.requiredPlugins = List<String>.from(metadataJson['Plugins']);
      }
    }

    final general = settingsJson['GeneralSettings'] as Map<String, dynamic>?;
    if (general != null) {
      settings.suggestedBots = general['SuggestedBots'] ?? 1;
      settings.maxCPM = general['MaximumCPM'] ?? 0;
      settings.saveEmptyCaptures = general['SaveEmptyCaptures'] ?? false;
      if (general['ContinueStatuses'] != null) {
        final continueStatuses = List<String>.from(
          general['ContinueStatuses'],
        );
        settings.continueOnCustom = continueStatuses.any(
          (status) => status.toUpperCase() == 'CUSTOM',
        );
      }
    }

    final proxy = settingsJson['ProxySettings'] as Map<String, dynamic>?;
    if (proxy != null) {
      settings.needsProxies = proxy['UseProxies'] ?? false;
      settings.maxProxyUses = proxy['MaxUsesPerProxy'] ?? 0;
      settings.banLoopEvasionOverride = proxy['BanLoopEvasion'] ?? -1;
      if (proxy['AllowedProxyTypes'] != null) {
        final allowedTypes = List<String>.from(
          proxy['AllowedProxyTypes'],
        ).map((t) => t.toUpperCase());
        settings.onlySocks =
            allowedTypes.isNotEmpty &&
            !allowedTypes.any((t) => t == 'HTTP' || t == 'HTTPS');
      }
    }

    final data = settingsJson['DataSettings'] as Map<String, dynamic>?;
    if (data != null) {
      settings.encodeData = data['UrlEncodeDataAfterSlicing'] ?? false;
      if (data['AllowedWordlistTypes'] != null) {
        final allowedWordlists = List<String>.from(
          data['AllowedWordlistTypes'],
        );
        if (allowedWordlists.isNotEmpty) {
          settings.allowedWordlist1 = allowedWordlists[0];
        }
        if (allowedWordlists.length > 1) {
          settings.allowedWordlist2 = allowedWordlists[1];
        }
      }
    }

    final input = settingsJson['InputSettings'] as Map<String, dynamic>?;
    if (input != null && input['CustomInputs'] != null) {
      settings.customInputs = (input['CustomInputs'] as List)
          .map(
            (json) => CustomInput(
              variableName: json['VariableName'] ?? '',
              description: json['Description'] ?? '',
              value: json['DefaultAnswer'] ?? '',
            ),
          )
          .toList();
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
