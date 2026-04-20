import '../client/http_client.dart';
import '../models/cache_stats.dart';
import '../models/health_status.dart';

/// Internal service for API cache and health operations.
///
/// Handles server-side cache statistics and API health checks.
/// Used internally by [FonikaTranslate] — not intended for direct use.
class CacheService {
  final FonikaHttpClient _client;

  CacheService(this._client);

  /// Retrieves server-side cache statistics.
  ///
  /// Returns a [CacheStats] containing hit rate, cached translations, etc.
  Future<CacheStats> getStats() async {
    final json = await _client.get('/api/v1/cache/stats');
    return CacheStats.fromJson(json);
  }

  /// Clears the server-side translation cache.
  ///
  /// This removes all cached translations from the API.
  Future<void> clear() async {
    await _client.post('/api/v1/cache/clear', {});
  }

  /// Checks the health status of the API and its dependencies.
  ///
  /// Returns a [HealthStatus] indicating if the API and database are healthy.
  Future<HealthStatus> healthCheck() async {
    final json = await _client.get('/health');
    return HealthStatus.fromJson(json);
  }
}
