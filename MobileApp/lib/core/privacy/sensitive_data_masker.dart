/// Masks vehicle / VIN / policy identifiers so raw values never hit the
/// on-device transcript. Keys and raw string values that match are reduced
/// to `****` + last 4 chars (e.g. `MH12AB1234` → `******1234`).
class SensitiveDataMasker {
  /// Normalised, lower-case, no-separator forms of every key we treat as PII.
  static const Set<String> _sensitiveKeys = {
    'vehiclenumber',
    'vehicleregistrationnumber',
    'vehicleregno',
    'vehiclereg',
    'vinnumber',
    'vin',
    'policynumber',
  };

  static String maskValue(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;
    if (v.length <= 4) return '*' * v.length;
    return '${'*' * (v.length - 4)}${v.substring(v.length - 4)}';
  }

  /// Deep-copies [data], masking string values under any sensitive key.
  static Map<String, dynamic> maskClaimData(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (_isSensitive(key) && value is String) {
        out[key] = maskValue(value);
      } else if (value is Map) {
        out[key] = maskClaimData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        out[key] = _maskList(value);
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Walks [data] and returns every raw sensitive string we can find, so they
  /// can be stripped from free-text message bodies too.
  static Set<String> extractSensitiveValues(Map<String, dynamic> data) {
    final values = <String>{};
    void walk(dynamic node, {bool parentIsSensitive = false}) {
      if (node is Map) {
        node.forEach((k, v) {
          final sensitive = k is String && _isSensitive(k);
          if (sensitive && v is String && v.trim().isNotEmpty) {
            values.add(v.trim());
          }
          walk(v, parentIsSensitive: sensitive);
        });
      } else if (node is List) {
        for (final e in node) {
          walk(e, parentIsSensitive: parentIsSensitive);
        }
      }
    }
    walk(data);
    return values;
  }

  /// Replaces every occurrence of a known raw value in [text] with its mask.
  static String maskText(String text, Iterable<String> rawValues) {
    if (text.isEmpty) return text;
    var out = text;
    for (final raw in rawValues) {
      if (raw.isEmpty) continue;
      out = out.replaceAll(raw, maskValue(raw));
    }
    return out;
  }

  static List<dynamic> _maskList(List<dynamic> list) {
    return list.map<dynamic>((e) {
      if (e is Map) return maskClaimData(Map<String, dynamic>.from(e));
      if (e is List) return _maskList(e);
      return e;
    }).toList();
  }

  static bool _isSensitive(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    return _sensitiveKeys.contains(normalized);
  }
}
