import 'package:postgres/postgres.dart';
import '../config/database.dart';
import '../models/resolved_link.dart';

class LinkRepository {
  final Pool _pool = DatabaseConfig.getPool();

  /// Obtiene los metadatos del lanzamiento y la ruta fisica/URL externa a partir del hash del enlace en release_links
  Future<ResolvedLink?> getUrlFromHash(String hash) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT r.filepath, l.url, r.id AS book_hash, r.series_id AS series_hash, r.title '
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
      final String? bookHash = row[2] as String?;
      final String? seriesHash = row[3] as String?;
      final String? title = row[4] as String?;
      
      return ResolvedLink(
        filepath: filepath,
        url: url,
        bookHash: bookHash,
        seriesHash: seriesHash,
        title: title,
      );
    } catch (e) {
      print('[ERROR] Error en getUrlFromHash en Dart: $e');
      return null;
    }
  }

  /// Registra de forma automatica una descarga en la tabla user_downloads de PostgreSQL
  Future<void> registerDownload({
    required String bookHash,
    required String? seriesHash,
    required String? title,
  }) async {
    try {
      // 1. Obtener un Telegram ID de usuario registrado y activo en la tabla users.
      // Esto evita violar la clave foranea si la descarga es anonima desde la web.
      final Result userResult = await _pool.execute(
        'SELECT telegram_id FROM users LIMIT 1'
      );
      
      if (userResult.isEmpty) {
        print('[WARN] No se encontraron usuarios registrados en la tabla users. Saltando registro de descarga.');
        return;
      }
      
      final int userId = userResult.first.first as int;
      
      // 2. Insertar la descarga de forma normalizada
      await _pool.execute(
        Sql.named(
          'INSERT INTO user_downloads (user_id, book_hash, series_hash, title, downloaded_at) '
          'VALUES (:userId, :bookHash, :seriesHash, :title, CURRENT_TIMESTAMP)'
        ),
        parameters: {
          'userId': userId,
          'bookHash': bookHash,
          'seriesHash': seriesHash,
          'title': title ?? 'Libro sin titulo',
        },
      );
      
      print('[INFO] Descarga registrada en user_downloads para bookHash: $bookHash');
    } catch (e) {
      print('[ERROR] Error al registrar descarga en user_downloads: $e');
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
