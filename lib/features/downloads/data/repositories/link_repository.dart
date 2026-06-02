import 'package:postgres/postgres.dart';
import '../../../../common/database/database.dart';
import '../../core/repositories/i_link_repository.dart';
import '../models/resolved_link.dart';

class LinkRepository implements ILinkRepository {
  final Pool _pool = DatabaseConfig.getPool();

  @override
  Future<ResolvedLink?> getUrlFromUuid(String uuid) async {
    try {
      final Result result = await _pool.execute(
        Sql.named(
          'SELECT r.filepath, l.url, r.id AS book_hash, r.series_id AS series_hash, r.title '
          'FROM release_links l '
          'LEFT JOIN milestone_releases r ON l.milestone_release_id = r.id '
          'WHERE l.id = :uuid '
          'LIMIT 1'
        ),
        parameters: {'uuid': uuid},
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
      print('[ERROR] Error en getUrlFromUuid en Dart: $e');
      return null;
    }
  }

  @override
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

  @override
  Future<void> updateUrlCache(String uuid, String newFilepath) async {
    try {
      await _pool.execute(
        Sql.named(
          'UPDATE milestone_releases '
          'SET filepath = :filepath '
          'WHERE id = ('
          '  SELECT milestone_release_id '
          '  FROM release_links '
          '  WHERE id = :uuid '
          '  LIMIT 1'
          ')'
        ),
        parameters: {
          'filepath': newFilepath,
          'uuid': uuid,
        },
      );
      print('[INFO] [Dart Cache] Ruta fisica actualizada en milestone_releases para el UUID "$uuid" con nueva ruta.');
    } catch (e) {
      print('[ERROR] Error al actualizar ruta fisica en Dart: $e');
    }
  }
}
