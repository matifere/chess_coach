# ♟️ Chess Coach

Un proyecto desarrollado en **Flutter** para aprender, entrenar y jugar ajedrez de forma personalizada. La aplicación está diseñada para ser multiplataforma (Móvil, Web y Escritorio) e interactuar con su propio motor neuronal de ajedrez basado en **Rust** para partidas y análisis.

---

## 🤖 Inteligencia Artificial 100% Local

A diferencia de otras aplicaciones que dependen de servidores en la nube para procesar las jugadas, **Chess Coach procesa todo el motor de ajedrez y la inteligencia artificial directamente en tu dispositivo (Offline)**. 
Gracias a la integración con código nativo en **Rust** y el uso de redes neuronales reales (NNUE), el bot es capaz de evaluar miles de posiciones instantáneamente simulando un estilo humano sin consumir datos ni requerir conexión a internet.

---

## ✨ Características Actuales

- 🧠 **Cerebro en Rust (Alpha-Beta + QS + NNUE):** Motor de búsqueda personalizado de alto rendimiento que evalúa posiciones usando la red neuronal NNUE. Incluye **Búsqueda de Quiescencia (QS)** para estabilizar combates tácticos.
- ⚡ **Arquitectura Asíncrona (Multithreading):** Todo el pensamiento de la IA y el cálculo de evaluación corren en subprocesos paralelos sin congelar jamás la interfaz de usuario.
- 🏅 **Sistema de Calidad de Jugada (Badges):** Analiza y categoriza visualmente tus movimientos (Brillante, Excelente, Bueno, Libro, Imprecisión, Error, Blunder). Utiliza la fórmula *Win Probability Loss (WPL)* matemática de Stockfish para asegurar total precisión independientemente de la ventaja en el tablero.
- 📊 **Barra de Evaluación Dinámica:** Una barra interactiva en tiempo real al estilo de las grandes plataformas que muestra exactamente quién tiene la ventaja. Además, el motor rastrea de manera exacta la "Distancia de Mate en N Plies" para mostrar mensajes letales como **M2** o **M5**.
- 🎚️ **Control Dinámico de Elo:** Ajusta la dificultad del Bot en tiempo real (desde 600 hasta 2200 Elo) mediante un slider interactivo que escala matemáticamente la profundidad de análisis del motor.
- 🎬 **Animaciones Fluidas (Sliding):** Las piezas se deslizan de forma natural (con curvas de aceleración y desaceleración) al realizar movimientos normales y enroques, brindando una experiencia visual premium.
- 📱 **Interfaz 100% Responsiva:** Adaptación automática del diseño. En pantallas amplias muestra un panel lateral de control, y en pantallas estrechas apila los elementos cómodamente.
- 🎨 **Gráficos de Alta Calidad:** Piezas y medallas en gráficos vectoriales (SVG) de Lichess y Chess.com, respetando relación de aspecto perfecta.
- 🖐️ **Drag & Drop Integrado:** Juega con clics tradicionales o arrastrando las piezas; las animaciones responden inteligentemente.
- 🌟 **Promoción In-Place:** Menú de coronación contextual e inteligente que se despliega exactamente sobre la casilla del peón.
- 🔄 **Cambio de Perspectiva:** Posibilidad de jugar con Blancas o Negras, el tablero rota y el Bot detecta automáticamente cuando es su turno de jugar.
- 🏳️ **Gestión de Partida:** Historial PGN en tiempo real, opciones para abandonar y botón de revancha rápida.

---

## 🛠️ Tecnologías Utilizadas

- **[Flutter](https://flutter.dev/):** Framework principal para la UI multiplataforma.
- **[Rust](https://www.rust-lang.org/):** Lenguaje nativo de ultra alto rendimiento utilizado para el motor de ajedrez y cálculo matemático.
- **[flutter_rust_bridge (v2)](https://fzyzcjy.github.io/flutter_rust_bridge/):** Puente asíncrono y seguro para gestionar los hilos entre Dart y Rust.
- **[nnue-rs](https://crates.io/crates/nnue-rs) & [shakmaty](https://crates.io/crates/shakmaty):** Librerías de Rust para manejo de estado legal e inferencia de red neuronal de ajedrez (NNUE).
- **[flutter_bloc](https://pub.dev/packages/flutter_bloc):** Manejo de estados de la aplicación utilizando la arquitectura *Cubit*.

---

## 🚀 Cómo ejecutar el proyecto

Asegúrate de tener instalado el SDK de **Flutter** y **Rust** (`cargo`) en tu sistema.

1. Clona el repositorio:
   ```bash
   git clone https://github.com/matifere/chess_coach.git
   ```
2. Entra al directorio del proyecto:
   ```bash
   cd chess_coach
   ```
3. Instala las dependencias y genera la conectividad Rust-Dart:
   ```bash
   flutter pub get
   flutter_rust_bridge_codegen generate
   ```
4. Compila y ejecuta la aplicación:
   ```bash
   flutter run
   ```

---

## 📅 Próximos pasos (Roadmap)
- [ ] Evaluar múltiples líneas principales (MultiPV) para sugerir la "Mejor Jugada" como un entrenador activo.
- [ ] Integración con cuentas en la nube (Supabase) para guardar historial, estadísticas y tácticas.
