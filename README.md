# ♟️ Chess Coach

Un proyecto desarrollado en **Flutter** para aprender, entrenar y jugar ajedrez de forma personalizada. La aplicación está diseñada para ser multiplataforma (Móvil, Web y Escritorio) e interactuar eventualmente con motores de ajedrez (bots) para partidas guiadas.

---

## ✨ Características Actuales

- 📱 **Interfaz 100% Responsiva:** Adaptación automática del diseño. En pantallas amplias muestra un panel lateral de control, y en pantallas estrechas apila los elementos cómodamente.
- 🎨 **Gráficos de Alta Calidad:** Utiliza gráficos vectoriales (SVG) de Lichess (estilo *cburnett*) para mantener una nitidez perfecta en cualquier resolución.
- 🖐️ **Drag & Drop Integrado:** Juega con clics tradicionales o arrastrando las piezas de forma fluida.
- 🌟 **Promoción In-Place:** Menú de coronación contextual e inteligente que se despliega exactamente sobre la casilla del peón.
- 🧠 **Reglas Oficiales:** Motor interno (mediante el paquete `chess`) para validar movimientos legales, jaques, jaque mates, enroques y capturas al paso.
- 🔄 **Cambio de Perspectiva:** Posibilidad de jugar tanto con **Blancas** como con **Negras**. El tablero se voltea automáticamente para mantener tu bando en la parte inferior.
- 🏳️ **Gestión de Partida:** Historial PGN en tiempo real, opciones para abandonar la partida y botón de revancha rápida (Nueva partida).

---

## 🛠️ Tecnologías Utilizadas

- **[Flutter](https://flutter.dev/):** Framework principal para la UI multiplataforma.
- **[flutter_bloc](https://pub.dev/packages/flutter_bloc):** Manejo de estados de la aplicación utilizando la arquitectura *Cubit*.
- **[flutter_svg](https://pub.dev/packages/flutter_svg):** Renderizado de las piezas en formato vectorial.
- **[chess (Dart)](https://pub.dev/packages/chess):** Lógica interna de validación y reglas del juego.

---

## 🚀 Cómo ejecutar el proyecto

Asegúrate de tener instalado el SDK de Flutter en tu sistema.

1. Clona el repositorio:
   ```bash
   git clone https://github.com/matifere/chess_coach.git
   ```
2. Entra al directorio del proyecto:
   ```bash
   cd chess_coach
   ```
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

---

## 📅 Próximos pasos (Roadmap)
- [ ] Integración con un motor de ajedrez (Stockfish / Bot) para jugar contra la máquina.
- [ ] Evaluador de ventajas / Barra de evaluación.
- [ ] (Opcional) Migración de módulos de cálculo pesado a Rust mediante `flutter_rust_bridge`.
