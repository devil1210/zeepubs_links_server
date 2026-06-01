import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../repositories/link_repository.dart';
import '../services/self_healing_service.dart';

class DownloadController {
  final LinkRepository _repository = LinkRepository();
  final SelfHealingService _healingService = SelfHealingService();

  Router get router {
    final router = Router();

    // Registrar endpoint de descarga por hash
    router.get('/api/dl/<hash>', _handleDownload);

    return router;
  }

  Future<Response> _handleDownload(Request request, String hash) async {
    print('📥 [Dart Shelf] Solicitud de descarga recibida para hash: $hash');

    try {
      // 1. Obtener la URL/Ruta desde el repositorio
      final originalPath = await _repository.getUrlFromHash(hash);
      if (originalPath == null) {
        print('❌ [Dart Shelf] Hash no encontrado en base de datos: $hash');
        return Response.notFound('Enlace no encontrado o expirado.');
      }

      // 2. Manejar descargas remotas HTTP/HTTPS si aplica (compatibilidad)
      if (originalPath.startsWith('http://') || originalPath.startsWith('https://')) {
        print('🔀 Redirigiendo descarga remota: $originalPath');
        return Response.movedPermanently(originalPath);
      }

      // 3. Resolver la ruta física local con Auto-Recuperación (Self-Healing)
      final resolvedPath = await _healingService.resolvePhysicalPath(originalPath, hash);
      if (resolvedPath == null) {
        print('❌ [Dart Shelf] Archivo físico local no disponible.');
        return Response.notFound('El archivo no está disponible.');
      }

      final file = File(resolvedPath);
      final filename = resolvedPath.split(Platform.pathSeparator).last;

      // 4. Servir el archivo físico local usando streaming asíncrono
      // openRead() abre un stream de bytes directos optimizado que no carga el archivo entero en memoria RAM
      final fileStream = file.openRead();
      final fileSize = await file.length();

      print('🚀 [Dart Shelf] Sirviendo archivo local de forma eficiente ($fileSize bytes): $resolvedPath');

      return Response.ok(
        fileStream,
        headers: {
          'Content-Type': 'application/epub+zip',
          'Content-Length': fileSize.toString(),
          'Content-Disposition': 'attachment; filename="$filename"',
          'Cache-Control': 'public, max-age=31536000', // Cache por 1 año
        },
      );

    } catch (e) {
      print('❌ Error interno del servidor en Dart: $e');
      return Response.internalServerError(body: 'Error interno al procesar la descarga.');
    }
  }
}
