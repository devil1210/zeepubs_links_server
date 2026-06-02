import 'dart:io';
import '../repositories/i_link_repository.dart';

class SelfHealingService {
  final ILinkRepository _repository;

  SelfHealingService(this._repository);

  /// Resuelve la ruta fisica del archivo local.
  /// Si el archivo ha sido movido o renombrado, intenta ubicarlo de forma proactiva
  /// y actualiza la ruta fisica si se encuentra una nueva ubicacion valida por UUID.
  Future<String?> resolvePhysicalPath(String originalPath, String uuid) async {
    // 1. Caso ideal: El archivo existe en la ruta original
    if (await File(originalPath).exists()) {
      return originalPath;
    }

    // 2. Auto-Recuperacion: El archivo se ha movido o renombrado
    print('[WARN] [Dart Self-Healing] Archivo no encontrado en: $originalPath');
    print('[INFO] Iniciando proceso de Auto-Recuperacion Dinamica en Dart...');

    final String filename = originalPath.split(Platform.pathSeparator).last;
    
    try {
      // Buscar en PostgreSQL por el nombre del archivo
      final String? newFilepath = await _repository.getFilepathByFilename(filename);

      if (newFilepath != null && await File(newFilepath).exists()) {
        print('[INFO] [Dart Self-Healing] Archivo auto-recuperado en nueva ruta: $newFilepath');

        // Actualizar la ruta fisica en la base de datos para futuras peticiones ultra-eficientes por UUID
        await _repository.updateUrlCache(uuid, newFilepath);
        
        return newFilepath;
      }
    } catch (e) {
      print('[ERROR] Error durante el proceso de Auto-Recuperacion en Dart: $e');
    }

    return null; // Archivo no encontrado en ningun lugar activo
  }
}
