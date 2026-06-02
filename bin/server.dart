import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dotenv/dotenv.dart';
import '../lib/common/database/database.dart';
import '../lib/features/downloads/presentation/download_controller.dart';

void main(List<String> args) async {
  print('[START] Inicializando ZeePubs Links Server (Dart Shelf)...');

  // 1. Cargar variables de entorno si existe un archivo .env
  final DotEnv env = DotEnv(includePlatformEnvironment: true)..load();
  
  final int port = int.tryParse(env['PORT'] ?? '8080') ?? 8080;
  final String host = env['HOST'] ?? '0.0.0.0';

  // 2. Inicializar base de datos
  try {
    DatabaseConfig.getPool();
  } catch (e) {
    print('[ERROR] Error al inicializar pool de base de datos: $e');
  }

  // 3. Configurar controladores y enrutamiento
  final DownloadController downloadController = DownloadController();

  // 4. Configurar pipeline de Middlewares y handlers de Shelf
  final Handler handler = Pipeline()
      .addMiddleware(logRequests()) // Logging de peticiones HTTP en consola
      .addMiddleware(_addCorsHeaders()) // Middleware opcional para CORS
      .addHandler(downloadController.router.call);

  // 5. Iniciar Servidor HTTP Shelf
  final HttpServer server = await shelf_io.serve(handler, host, port);
  print('[INFO] Servidor de Links en Dart activo escuchando en http://${server.address.host}:${server.port}');

  // 6. Manejar cierre ordenado (SIGINT / SIGTERM)
  ProcessSignal.sigint.watch().listen((ProcessSignal sig) => _shutdown(sig, server));
  ProcessSignal.sigterm.watch().listen((ProcessSignal sig) => _shutdown(sig, server));
}

/// Middleware simple para añadir cabeceras CORS
Middleware _addCorsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      final Response response = await innerHandler(request);
      return response.change(headers: <String, String>{
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      });
    };
  };
}

/// Detencion controlada del servidor y sus conexiones
void _shutdown(ProcessSignal sig, HttpServer server) async {
  print('\n[INFO] Recibida senal ${sig.name}. Apagando el servidor en Dart...');
  await server.close(force: true);
  await DatabaseConfig.close();
  print('[INFO] Servidor apagado limpiamente.');
  exit(0);
}
