import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseConfig {
  static Pool? _pool;

  /// Inicializa el Pool de conexiones a PostgreSQL usando DATABASE_URL
  static Pool getPool() {
    if (_pool != null) return _pool!;

    final String dbUrl = Platform.environment['DATABASE_URL'] ?? 
        'postgresql://postgres:postgres@localhost:5432/zeepub_bot';

    print('[INFO] Conectando al Pool de base de datos PostgreSQL en Dart...');
    
    // Configurar endpoints del Pool
    _pool = Pool.withEndpoints(
      <Endpoint>[Endpoint.parse(dbUrl)],
      settings: const PoolSettings(
        maxConnectionCount: 15,
        sslMode: SslMode.disable, // Ajustar segun produccion
      ),
    );

    return _pool!;
  }

  /// Cierra todas las conexiones del Pool ordenadamente
  static Future<void> close() async {
    if (_pool != null) {
      print('[INFO] Cerrando conexiones del Pool PostgreSQL...');
      await _pool!.close();
      _pool = null;
    }
  }
}
