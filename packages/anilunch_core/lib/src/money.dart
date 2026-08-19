/// Money is an integer number of paise (1/100 of a rupee).
///
/// The Go API is authoritative for money and always encodes monetary
/// amounts as integer paise in JSON. Clients must never compute totals for
/// money flows — this type exists for safe display and idempotent payloads.
class Money implements Comparable<Money> {
  final int paise;

  const Money(this.paise);

  static const Money zero = Money(0);

  /// Builds money from a rupee-denominated value (for display helpers only).
  factory Money.fromRupees(num rupees) => Money((rupees * 100).round());

  factory Money.fromJson(Object? value) => Money((value as num).toInt());

  double toRupees() => paise / 100;

  String format({bool withSymbol = true}) {
    final r = toRupees();
    final s = r.toStringAsFixed(2);
    return withSymbol ? '₹$s' : s;
  }

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator *(int factor) => Money(paise * factor);

  bool operator <(Money other) => paise < other.paise;
  bool operator >(Money other) => paise > other.paise;
  bool operator <=(Money other) => paise <= other.paise;
  bool operator >=(Money other) => paise >= other.paise;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => 'Money($paise)';
}

/// Helpers for lenient JSON decoding shared by every model.
String str(Map<String, dynamic> json, String key, [String fallback = '']) {
  final v = json[key];
  return v is String ? v : fallback;
}

String? optStr(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is String ? v : null;
}

int intOf(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final v = json[key];
  return v is num ? v.toInt() : fallback;
}

double doubleOf(Map<String, dynamic> json, String key, [double fallback = 0]) {
  final v = json[key];
  return v is num ? v.toDouble() : fallback;
}

bool boolOf(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final v = json[key];
  return v is bool ? v : fallback;
}

double? optDouble(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is num ? v.toDouble() : null;
}

DateTime dateTimeOf(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
