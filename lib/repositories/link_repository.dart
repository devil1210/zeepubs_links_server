import 'package:postgres/postgres.dart';
import '../config/database.dart';

class LinkRepository {
  final Pool _pool = DatabaseConfig.getPool();

  /// Obtiene la ruta fisica del libro o la URL externa a partir del hash del enlace en release_links
  Future<String?> getUrlFromHash(String hash) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT r.filepath, l.url '
          'FROM release_links l '
          'LEFT JOIN milestone_releases r ON l.milestone_release_id = r.id '
          'WHERE l.hash = :hash '
          'LIMIT 1'
        ),
        parameters: {'hash': hash},
      );

      if (result.isEmpty) return null;
      
      final ResultRow row = result.first;
      final String? filepath = row[0] as String?;
      final String? url = row[1] as String?;
      
      return filepath ?? url;
    } catch (e) {
      print('[ERROR] Error en getUrlFromHash en Dart: $e');
      return null;
    }
  }

  /// Busca el filepath de un libro en la tabla milestone_releases a partir de su filename
  Future<String?> getFilepathByFilename(String filename) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT filepath '
          'FROM milestone_releases '
          'WHERE filename = :filename '
          'LIMIT 1'
        ),
        parameters: {'filename': filename},
      );

      if (result.isEmpty) return null;
      return result.first.first as String?;
    } catch (e) {
      print('[ERROR] Error en getFilepathByFilename en Dart: $e');
      return null;
    }
  }

  /// Actualiza la ruta fisica en milestone_releases tras una auto-recuperacion exitosa (Self-Healing)
  Future<void> updateUrlCache(String hash, String newFilepath) async {
    try {
      await _pool.execute(
        Sql.named(
          'UPDATE milestone_releases '
          'SET filepath = :filepath '
          'WHERE id = ('
          '  SELECT milestone_release_id '
          '  FROM release_links '
          '  WHERE hash = :hash '
          '  LIMIT 1'
          ')'
        ),
        parameters: {
          'filepath': newFilepath,
          'hash': hash,
        },
      );
      print('[INFO] [Dart Cache] Ruta fisica actualizada en milestone_releases para el hash "$hash" con nueva ruta.');
    } catch (e) {
      print('[ERROR] Error al actualizar ruta fisica en Dart: $e');
    }
  }
}
