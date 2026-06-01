import 'package:postgres/postgres.dart';
import '../config/database.dart';

class LinkRepository {
  final Pool _pool = DatabaseConfig.getPool();

  /// Obtiene la URL mapeada a partir de su hash en url_mappings
  Future<String?> getUrlFromHash(String hash) async {
    try {
      final result = await _pool.execute(
        Sql.named('SELECT url FROM url_mappings WHERE hash = :hash LIMIT 1'),
        parameters: {'hash': hash},
      );

      if (result.isEmpty) return null;
      return result.first.first as String?;
    } catch (e) {
      print('❌ Error en getUrlFromHash en Dart: $e');
      return null;
    }
  }

  /// Busca el filepath de un libro en la tabla books a partir de su filename
  Future<String?> getFilepathByFilename(String filename) async {
    try {
      final result = await _pool.execute(
        Sql.named('SELECT filepath FROM books WHERE filename = :filename LIMIT 1'),
        parameters: {'filename': filename},
      );

      if (result.isEmpty) return null;
      return result.first.first as String?;
    } catch (e) {
      print('❌ Error en getFilepathByFilename en Dart: $e');
      return null;
    }
  }

  /// Actualiza la URL física en url_mappings tras una auto-recuperación exitosa (Self-Healing)
  Future<void> updateUrlCache(String hash, String newFilepath) async {
    try {
      await _pool.execute(
        Sql.named('UPDATE url_mappings SET url = :url WHERE hash = :hash'),
        parameters: {
          'url': newFilepath,
          'hash': hash,
        },
      );
      print('🔄 [Dart Cache] URL actualizada para el hash "$hash" con nueva ruta.');
    } catch (e) {
      print('❌ Error al actualizar caché de URL en Dart: $e');
    }
  }
}
