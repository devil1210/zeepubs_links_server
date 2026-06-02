import '../../data/models/resolved_link.dart';

abstract class ILinkRepository {
  /// Obtiene los metadatos del lanzamiento y la ruta fisica/URL externa a partir del UUID del enlace
  Future<ResolvedLink?> getUrlFromUuid(String uuid);

  /// Busca el filepath de un libro a partir de su filename (para Auto-Recuperacion)
  Future<String?> getFilepathByFilename(String filename);

  /// Actualiza la ruta fisica del libro tras una auto-recuperacion exitosa por UUID
  Future<void> updateUrlCache(String uuid, String newFilepath);
}
