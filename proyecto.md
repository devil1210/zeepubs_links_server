# 🌌 Manifesto de Operación Zeepubs Links Server v1.0.0 (Enterprise)

Este archivo es la **Única Fuente de Verdad** para el comportamiento del asistente de Antigravity en este nuevo workspace independiente. Se carga automáticamente al iniciar la sesión.

## 📌 Reglas Universales de Comportamiento

1.  **Idioma**: Responde SIEMPRE en **español**, a menos que se te pida explícitamente lo contrario.
2.  **Stack Tecnológico**:
    *   **Core**: Dart SDK (moderno, tipado estricto, async/await).
    *   **Framework HTTP**: **Shelf** y **Shelf Router** (micro-framework oficial y ultra-ligero).
    *   **Base de Datos**: PostgreSQL mediante la librería nativa `postgres` (usando `Pool` de conexiones asíncronas).
3.  **Clean Architecture Estricta**:
    *   `bin/server.dart`: Punto de entrada único del servidor HTTP.
    *   `lib/config/`: Ajustes de base de datos e infraestructura.
    *   `lib/controllers/`: Controladores de Shelf que manejan peticiones HTTP y streaming.
    *   `lib/repositories/`: Clases de acceso a datos con consultas seguras preparadas (`Sql.named`).
    *   `lib/services/`: Lógica de negocio pura (como la auto-recuperación y validaciones).
4.  **Auto-Recuperación Dinámica (Self-Healing)**:
    *   Si el path de un archivo local no se encuentra en el disco del servidor, se debe consultar dinámicamente PostgreSQL para buscar su reubicación por `filename` en la tabla `books`.
    *   Al resolver con éxito la nueva ubicación, se debe actualizar transparentemente la tabla de caché `url_mappings` para optimizar descargas futuras.
5.  **Seguridad y Proxy**:
    *   Queda terminantemente PROHIBIDO exponer rutas locales o paths absolutos del servidor en cabeceras o URLs públicas.
    *   Las descargas se sirven mediante streaming de bytes utilizando `openRead()` para evitar cargar archivos en memoria RAM.
6.  **Despliegue y Compilación**:
    *   Mantener el código listo para compilación nativa **AOT** (`dart compile exe`) libre de dependencias.
    *   Mantener el Dockerfile optimizado para imágenes minimalistas (distroless o Debian slim).
7.  **Sincronización con zeepubs_server**:
    *   Este microservicio debe estar perfectamente alineado y sincronizado con los cambios y actualizaciones del repositorio principal de **zeepubs_server** (https://github.com/zeedif/zeepubs_server).
    *   Ante cualquier modificación o actualización de esquemas, tablas o relaciones en el servidor principal, el asistente de Antigravity debe auditar la integración y actualizar los repositorios y modelos de datos en este proyecto para garantizar compatibilidad total sin interrupciones.


---
*ZeePubs Links Server: Rendimiento ultra-alto y descargas eternas en Dart.*
