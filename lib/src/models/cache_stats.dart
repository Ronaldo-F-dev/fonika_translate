class CacheStats {
  final int totalCached;
  final int totalHits;
  final String hitRate;
  final List<dynamic> topTranslations;
  final int localDatabaseEntries;

  const CacheStats({
    required this.totalCached,
    required this.totalHits,
    required this.hitRate,
    required this.topTranslations,
    required this.localDatabaseEntries,
  });

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
