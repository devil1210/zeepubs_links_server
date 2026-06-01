# 🌌 ZeePubs Links Server — Microservicio en Dart Shelf

Este es un microservicio backend independiente, modular y de rendimiento ultra-alto, escrito en **Dart** utilizando el framework estándar de la comunidad **Shelf**.

Ha sido diseñado específicamente para el **Paso 2** de la reestructuración de la arquitectura de **ZeePub-bot**, asumiendo el tráfico pesado de descarga de libros y la lógica de redirección y **Auto-Recuperación Dinámica (Self-Healing)** con un consumo minúsculo de memoria RAM y CPU en producción.

---

## 🚀 Características
*   **Connection Pooling**: Conexión ultra-eficiente a PostgreSQL en Dart usando la librería oficial `postgres`.
*   **Auto-Recuperación Dinámica (Self-Healing)**: Si un libro físico se mueve de carpeta o se renombra en el disco del servidor, el endpoint `/api/dl/<hash>` lo busca dinámicamente en la tabla `books` por su nombre de archivo, lo sirve transparentemente y actualiza la caché del hash para descargas futuras.
*   **Asynchronous I/O Streaming**: Sirve archivos locales transmitiendo bytes directamente en tiempo real (`openRead()`), evitando cargar archivos pesados en memoria RAM.
*   **Compilador Nativo AOT**: Puede compilarse a un ejecutable nativo de máquina libre de dependencias y de inicio inmediato (< 5 ms).

---

## 🛠️ Requisitos
*   **Dart SDK**: `>= 3.0.0` instalado en tu sistema.
*   **PostgreSQL**: Base de datos Postgres en ejecución (local o VPS).

---

## ⚙️ Configuración (Variables de Entorno)
Puedes configurar el servidor mediante un archivo `.env` en la raíz del proyecto o definiéndolas en el shell:

```env
PORT=8080
HOST=0.0.0.0
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/zeepub_bot
```

---

## ⚡ Ejecución en Desarrollo

1.  **Obtener dependencias**:
    ```bash
    dart pub get
    ```

2.  **Ejecutar el servidor**:
    ```bash
    dart run bin/server.dart
    ```

---

## 🏗️ Compilación Nativa AOT (Producción)

Una de las mayores ventajas de Dart es la capacidad de compilar todo el backend a un solo archivo binario ejecutable que corre sin necesidad de tener el runtime de Dart instalado:

*   **En Windows**:
    ```bash
    dart compile exe bin/server.dart -o bin/server.exe
    ```

*   **En Linux (VPS)**:
    ```bash
    dart compile exe bin/server.dart -o bin/server
    ```

El binario resultante se ejecuta directamente con:
```bash
./bin/server
```

---

## 🐳 Despliegue con Docker
Para desplegar de forma aislada en tu infraestructura, puedes usar un Dockerfile multi-stage ligero para Dart:

```dockerfile
# Stage 1: Build AOT binary
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Minimal runtime image
FROM subfuzion/dumb-init:latest AS init
FROM debian:bookworm-slim
COPY --from=init /usr/local/bin/dumb-init /usr/local/bin/dumb-init
WORKDIR /app
COPY --from=build /app/bin/server /app/server
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/app/server"]
```
