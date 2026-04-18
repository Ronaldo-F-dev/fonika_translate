class HealthStatus {
  final String status;
  final String message;
  final String database;

  const HealthStatus({
    required this.status,
    required this.message,
    required this.database,
  });

  bool get isHealthy => status == 'healthy';
  bool get isDatabaseConnected => database == 'connected';

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
