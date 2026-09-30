# Sudoku Senior 🔢👓 — Accessible Brain Fitness & Classic Sudoku

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Accessibility](https://img.shields.io/badge/UX-Senior%20Friendly%20%7C%20High%20Contrast-green)]()
[![Author](https://img.shields.io/badge/Studio-Inventus%20Tech-orange)]()

> **Sudoku Senior** es un videojuego de lógica matemática adaptado especialmente para adultos mayores y personas que buscan una experiencia de juego limpia, sin estrés y de alta accesibilidad. Incorpora números de gran tamaño, tipografía de alto contraste, controles táctiles amplios y un sistema motivacional de frases célebres desbloqueables como recompensa.

---

## 🌟 Características Principales

* **Diseño Orientado a la Accesibilidad (*Senior Friendly*):**
  * Cuadrículas con números legibles y contraste optimizado para reducir la fatiga visual.
  * Teclado numérico amplio con retroalimentación háptica y visual intuitiva.
* **Múltiples Niveles de Dificultad & Modo Reto Diabólico:**
  * Modos: *Fácil, Medio, Difícil* y el exclusivo *Modo Diabólico* (desbloqueable tras completar 10 victorias en el Modo Reto Maestro).
* **Sistema de Recompensas y Frases Coleccionables:**
  * Al completar tableros, el jugador desbloquea citas inspiradoras y proverbios clásicos en su galería personal.
* **Persistencia Blindada en Memoria y Disco:**
  * Almacenamiento local mediante `GameStorage` con caché de preferencias en memoria para agilidad instantánea.
  * Respaldo automático de partidas en curso (`current_game_state_backup`) para que el usuario pueda pausar su juego y continuarlo más tarde sin riesgo de perder su progreso.

---

## 🏗️ Estructura del Código

```
sudoku_senior/
├── lib/
│   ├── managers/
│   │   ├── game_storage.dart        # Gestor de persistencia, respaldo y estadísticas
│   │   └── sudoku_generator.dart    # Algoritmo de generación de tableros válidos
│   ├── models/
│   │   ├── game_state.dart          # Estado de la cuadrícula, notas y tiempo
│   │   └── quote_item.dart          # Frases motivacionales desbloqueables
│   ├── screens/
│   │   ├── game_screen.dart         # Pantalla interactiva del tablero
│   │   ├── mode_selection_screen.dart # Selector de dificultad
│   │   └── gallery_screen.dart      # Galería de frases y logros obtenidos
│   └── main.dart                    # Configuración de tema accesible
```

---

## 🚀 Puesta en Marcha

```bash
cd Sudoku/Sudoku/sudoku_senior
flutter pub get
flutter run
```

---

**Desarrollado por Inventus Tech Studio** • *Liderado por Samuel Henríquez*
