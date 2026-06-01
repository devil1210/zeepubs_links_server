import 'package:postgres/postgres.dart';
import '../config/database.dart';
import '../models/resolved_link.dart';

class LinkRepository {
  final Pool _pool = DatabaseConfig.getPool();

  /// Obtiene los metadatos del libro y la ruta fisica a partir del UUID del libro en la tabla books
  Future<ResolvedLink?> getUrlFromUuid(String uuid) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT filepath, id AS book_hash, series_id AS series_hash, title '
          'FROM books '
          'WHERE uuid = :uuid '
          'LIMIT 1'
        ),
        parameters: {'uuid': uuid},
      );

      if (result.isEmpty) return null;
      
      final ResultRow row = result.first;
      final String? filepath = row[0] as String?;
      final String? bookHash = row[1] as String?;
      final String? seriesHash = row[2] as String?;
      final String? title = row[3] as String?;
      
      return ResolvedLink(
        filepath: filepath,
        url: null, // Resolucion directa de archivo fisico
        bookHash: bookHash,
        seriesHash: seriesHash,
        title: title,
      );
    } catch (e) {
      print('[ERROR] Error en getUrlFromUuid en Dart: $e');
      return null;
    }
  }

  /// Busca el filepath de un libro en la tabla books a partir de su filename (para Auto-Recuperacion)
  Future<String?> getFilepathByFilename(String filename) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT filepath '
          'FROM books '
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

  /// Actualiza la ruta fisica en books tras una auto-recuperacion exitosa (Self-Healing) por UUID
  Future<void> updateUrlCache(String uuid, String newFilepath) async {
    try {
      await _pool.execute(
        Sql.named(
          'UPDATE books '
          'SET filepath = :filepath '
          'WHERE uuid = :uuid'
        ),
        parameters: {
          'filepath': newFilepath,
          'uuid': uuid,
        },
      );
      print('[INFO] [Dart Cache] Ruta fisica actualizada en books para el UUID "$uuid" con nueva ruta.');
    } catch (e) {
      print('[ERROR] Error al actualizar ruta fisica en Dart: $e');
    }
  }
}
