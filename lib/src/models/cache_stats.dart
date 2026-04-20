/// Statistics about server-side API cache and database.
class CacheStats {
  /// Total number of translations cached on the server.
  final int totalCached;

  /// Total number of cache hits.
  final int totalHits;

  /// Cache hit rate as a percentage string (e.g. '85.5%').
  final String hitRate;

  /// List of most frequently cached translations.
  final List<dynamic> topTranslations;

  /// Number of entries in the local database on the server.
  final int localDatabaseEntries;

  const CacheStats({
    required this.totalCached,
    required this.totalHits,
    required this.hitRate,
    required this.topTranslations,
    required this.localDatabaseEntries,
  });

  /// Creates a [CacheStats] from API JSON response.
  factory CacheStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final cache = data['cache'] as Map<String, dynamic>;
    final db = data['local_database'] as Map<String, dynamic>? ?? {};
    return CacheStats(
      totalCached: cache['total_cached_translations'] as int,
      totalHits: cache['total_cache_hits'] as int,
      hitRate: cache['cache_hit_rate'] as String,
      topTranslations: cache['top_translations'] as List<dynamic>? ?? [],
      localDatabaseEntries: db['total_entries'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'CacheStats(cached: $totalCached, hits: $totalHits, rate: $hitRate)';
}
