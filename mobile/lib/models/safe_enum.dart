/// Tolerant enum parsing shared across models.
///
/// Never throws on unknown strings — falls back to [fallback] so records
/// written by the web app (or legacy local data) with a slightly different
/// vocabulary are never silently dropped. [aliases] maps alternate spellings
/// (e.g. web-only values) to this app's enum value.
T safeEnum<T extends Enum>(
  dynamic value,
  List<T> values,
  T fallback, {
  Map<String, T> aliases = const {},
}) {
  if (value is! String) return fallback;
  final v = value.trim();
  if (v.isEmpty) return fallback;
  for (final e in values) {
    if (e.name == v) return e;
  }
  final lower = v.toLowerCase();
  for (final e in values) {
    if (e.name.toLowerCase() == lower) return e;
  }
  for (final entry in aliases.entries) {
    if (entry.key == v || entry.key.toLowerCase() == lower) return entry.value;
  }
  return fallback;
}
