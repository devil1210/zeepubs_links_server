# 🌌 Guía de Inteligencia del Agente — Zeepubs Links Server

Este archivo sirve para instruir al agente de Antigravity sobre cómo comprender, mantener y expandir de forma óptima el microservicio **zeepubs_links_server** en Dart.

## Principios para el Agente

### 1. Desarrollo Idiomático en Dart
*   **Tipado Estricto**: Utiliza siempre tipos explícitos para variables locales, retornos de funciones y parámetros (evitar el uso excesivo de `dynamic`).
*   **Programación Asíncrona**: Dart es asíncrono y monohilo por defecto. Utiliza `Future` y `Stream` de manera eficiente.
*   **Higiene de Emojis**: Evita el uso de emojis o caracteres unicode especiales en logs (`logger.info`, `print`), ya que los VPS o terminales Windows con codificación por defecto (cp1252) arrojarán excepciones fatales de codificación (`UnicodeEncodeError`).

### 2. Estructura de Capas (Clean Architecture)
El agente debe respetar y mantener la separación estricta de responsabilidades:
*   Cualquier endpoint nuevo debe registrarse en un controlador de Shelf bajo `lib/controllers/` y enlazarse en `bin/server.dart`.
*   Cualquier consulta a PostgreSQL debe implementarse en un repositorio en `lib/repositories/` usando consultas preparadas (`Sql.named`).
*   Toda lógica de negocio pura y de toma de decisiones debe vivir en un servicio en `lib/services/`.

### 3. Streaming Asíncrono de Archivos
*   Al servir archivos físicos, utiliza siempre `file.openRead()` en Dart. Nunca leas todo el archivo a memoria (`readAsBytes()`) para servirlo en una petición HTTP, ya que esto causaría picos severos de consumo de memoria RAM.

### 4. Herramientas Útiles de Dart CLI
*   Para descargar dependencias: `dart pub get`
*   Para correr en desarrollo: `dart run bin/server.dart`
*   Para verificar análisis estático: `dart analyze`
*   Para compilar binario de producción AOT: `dart compile exe bin/server.dart -o bin/server`

---
*ZeePubs Links Server: Compilado a nativo para máxima velocidad y eficiencia.*
