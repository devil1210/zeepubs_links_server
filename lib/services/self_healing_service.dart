import 'dart:io';
import '../repositories/link_repository.dart';

class SelfHealingService {
  final LinkRepository _repository = LinkRepository();

  /// Resuelve la ruta física del archivo local.
  /// Si el archivo ha sido movido o renombrado, intenta ubicarlo de forma proactiva
  /// y actualiza la caché del hash si se encuentra una nueva ubicación válida.
  Future<String?> resolvePhysicalPath(String originalPath, String hash) async {
    // 1. Caso ideal: El archivo existe en la ruta original
    if (await File(originalPath).exists()) {
      return originalPath;
    }

    // 2. Auto-Recuperación: El archivo se ha movido o renombrado
    print('⚠️ [Dart Self-Healing] Archivo no encontrado en: $originalPath');
    print('🔍 Iniciando proceso de Auto-Recuperación Dinámica en Dart...');

    final filename = originalPath.split(Platform.pathSeparator).last;
    
    try {
      // Buscar en PostgreSQL por el nombre del archivo
      final newFilepath = await _repository.getFilepathByFilename(filename);

      if (newFilepath != null && await File(newFilepath).exists()) {
        print('✅ [Dart Self-Healing] ¡Archivo auto-recuperado en nueva ruta!: $newFilepath');

        // Actualizar la caché de url_mappings para futuras peticiones ultra-eficientes
        await _repository.updateUrlCache(hash, newFilepath);
        
        return newFilepath;
      }
    } catch (e) {
      print('❌ Error durante el proceso de Auto-Recuperación en Dart: $e');
    }

    return null; // Archivo no encontrado en ningún lugar activo
  }
}
