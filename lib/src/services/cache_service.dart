import '../client/http_client.dart';
import '../models/cache_stats.dart';
import '../models/health_status.dart';

class CacheService {
  final FonikaHttpClient _client;

  CacheService(this._client);

  Future<CacheStats> getStats() async {
    final json = await _client.get('/api/v1/cache/stats');
    return CacheStats.fromJson(json);
  }

  Future<void> clear() async {
    await _client.post('/api/v1/cache/clear', {});
  }

  Future<HealthStatus> healthCheck() async {
    final json = await _client.get('/health');
    return HealthStatus.fromJson(json);
  }
}
