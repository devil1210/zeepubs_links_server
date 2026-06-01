import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../repositories/link_repository.dart';
import '../services/self_healing_service.dart';
import '../models/resolved_link.dart';

class DownloadController {
  final LinkRepository _repository = LinkRepository();
  final SelfHealingService _healingService = SelfHealingService();

  Router get router {
    final Router router = Router();

    // Registrar endpoint de descarga por hash
    router.get('/api/dl/<hash>', _handleDownload);

    return router;
  }

  Future<Response> _handleDownload(Request request, String hash) async {
    print('[INFO] [Dart Shelf] Solicitud de descarga recibida para hash: $hash');

    try {
      // 1. Obtener los metadatos y la URL/Ruta desde el repositorio
      final ResolvedLink? resolvedLink = await _repository.getUrlFromHash(hash);
      if (resolvedLink == null) {
        print('[ERROR] [Dart Shelf] Hash no encontrado en base de datos: $hash');
        return Response.notFound('Enlace no encontrado o expirado.');
      }

      final String? originalPath = resolvedLink.filepath;
      final String? externalUrl = resolvedLink.url;

      // 2. Manejar descargas remotas HTTP/HTTPS si aplica (compatibilidad)
      if (originalPath == null && externalUrl != null) {
        if (externalUrl.startsWith('http://') || externalUrl.startsWith('https://')) {
          print('[INFO] Redirigiendo descarga remota: $externalUrl');
          
          // Registrar descarga de forma asincrona sin bloquear la respuesta HTTP
          if (resolvedLink.bookHash != null) {
            _repository.registerDownload(
              bookHash: resolvedLink.bookHash!,
              seriesHash: resolvedLink.seriesHash,
              title: resolvedLink.title,
            ).catchError((Object e) {
              print('[ERROR] Error en registro asincrono: $e');
              return null;
            });
          }
          
          return Response.movedPermanently(externalUrl);
        }
      }

      if (originalPath == null) {
        print('[ERROR] [Dart Shelf] No se especifico ruta fisica ni URL externa para el hash: $hash');
        return Response.notFound('El archivo no está disponible.');
      }

      // 3. Resolver la ruta fisica local con Auto-Recuperacion (Self-Healing)
      final String? resolvedPath = await _healingService.resolvePhysicalPath(originalPath, hash);
      if (resolvedPath == null) {
        print('[ERROR] [Dart Shelf] Archivo fisico local no disponible.');
        return Response.notFound('El archivo no está disponible.');
      }

      final File file = File(resolvedPath);
      final String filename = resolvedPath.split(Platform.pathSeparator).last;

      // 4. Servir el archivo fisico local usando streaming asincrono
      final Stream<List<int>> fileStream = file.openRead();
      final int fileSize = await file.length();

      print('[INFO] [Dart Shelf] Sirviendo archivo local de forma eficiente ($fileSize bytes): $resolvedPath');

      // Registrar descarga de forma asincrona sin bloquear la respuesta HTTP
      if (resolvedLink.bookHash != null) {
        _repository.registerDownload(
          bookHash: resolvedLink.bookHash!,
          seriesHash: resolvedLink.seriesHash,
          title: resolvedLink.title,
        ).catchError((Object e) {
          print('[ERROR] Error en registro asincrono: $e');
          return null;
        });
      }

      return Response.ok(
        fileStream,
        headers: <String, String>{
          'Content-Type': 'application/epub+zip',
          'Content-Length': fileSize.toString(),
          'Content-Disposition': 'attachment; filename="$filename"',
          'Cache-Control': 'public, max-age=31536000', // Cache por 1 ano
        },
      );

    } catch (e) {
      print('[ERROR] Error interno del servidor en Dart: $e');
      return Response.internalServerError(body: 'Error interno al procesar la descarga.');
    }
  }
}
