import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dotenv/dotenv.dart';
import '../lib/config/database.dart';
import '../lib/controllers/download_controller.dart';

void main(List<String> args) async {
  print('=== 🌌 Inicializando ZeePubs Links Server (Dart Shelf) ===');

  // 1. Cargar variables de entorno si existe un archivo .env
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final port = int.tryParse(env['PORT'] ?? '8080') ?? 8080;
  final host = env['HOST'] ?? '0.0.0.0';

  // 2. Inicializar base de datos
  try {
    DatabaseConfig.getPool();
  } catch (e) {
    print('❌ Error al inicializar pool de base de datos: $e');
  }

  // 3. Configurar controladores y enrutamiento
  final downloadController = DownloadController();

  // 4. Configurar pipeline de Middlewares y handlers de Shelf
  final handler = Pipeline()
      .addMiddleware(logRequests()) // Logging de peticiones HTTP en consola
      .addMiddleware(_addCorsHeaders()) // Middleware opcional para CORS
      .addHandler(downloadController.router.call);

  // 5. Iniciar Servidor HTTP Shelf
  final server = await shelf_io.serve(handler, host, port);
  print('✅ Servidor de Links en Dart activo escuchando en http://${server.address.host}:${server.port}');

  // 6. Manejar cierre ordenado (SIGINT / SIGTERM)
  ProcessSignal.sigint.watch().listen((_) => _shutdown(server));
  ProcessSignal.sigterm.watch().listen((_) => _shutdown(server));
}

/// Middleware simple para añadir cabeceras CORS
Middleware _addCorsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      });
    };
  };
}

/// Detención controlada del servidor y sus conexiones
void _shutdown(HttpServer server) async {
  print('\n⏹️ Apagando el servidor en Dart...');
  await server.close(force: true);
  await DatabaseConfig.close();
  print('✨ Servidor apagado limpiamente. ¡Hasta luego!');
  exit(0);
}
