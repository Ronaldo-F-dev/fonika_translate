/// Health status of the API and its dependencies.
class HealthStatus {
  /// Overall health status ('healthy', 'degraded', etc).
  final String status;

  /// Human-readable health message.
  final String message;

  /// Database connection status ('connected', 'disconnected', etc).
  final String database;

  const HealthStatus({
    required this.status,
    required this.message,
    required this.database,
  });

  /// Returns true if the API is healthy.
  bool get isHealthy => status == 'healthy';

  /// Returns true if the database is connected.
  bool get isDatabaseConnected => database == 'connected';

  /// Creates a [HealthStatus] from API JSON response.
  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String,
      message: json['message'] as String,
      database: json['database'] as String,
    );
  }

  @override
  String toString() => 'HealthStatus(status: $status, db: $database)';
}
