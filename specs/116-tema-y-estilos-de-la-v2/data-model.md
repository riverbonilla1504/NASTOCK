# Modelo (Fase 1): HU-116 · Identidad visual y sistema de diseño

La historia no maneja entidades de datos. Lo que se modela son los **tokens** del sistema visual, que viven en `lib/app/tema.dart` y se documentan en `DESIGN.md`.

## Colores

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `grafito` | #27272A | #26262A | Barra superior, aviso temporal |
| `sobreGrafito` | #F4F4F5 | #F4F4F5 | Texto sobre grafito (13,6:1) |
| `sobreGrafitoSuave` | #B4B4BC | #A9A9B2 | Texto secundario sobre grafito |
| `moradoSobreGrafito` | #C2B3FF | #C2B3FF | Aguja de ahora sobre grafito |
| `tinta` | #18181B | #EDEDEF | Texto, botón primario, bordes fuertes |
| `tintaSuave` | #52525B | #A1A1AA | Texto secundario |
| `tintaTenue` | #6B6B74 | #8B8B94 | Fines de semana, deshabilitado |
| `papel` | #F2F2F3 | #111113 | Fondo de pantalla |
| `hoja` | #FFFFFF | #1C1C1F | Listas, tarjetas, hojas |
| `regla` | tinta al 12 % | tinta al 12 % | Separadores |
| `reglaFuerte` | tinta al 30 % | tinta al 30 % | Bordes de campos y chips |
| `morado` | #6A45E0 | #B3A1FF | Líneas de gráfica, hoy, foco |
| `moradoTenue` | #ECE8FD | #2E2850 | Fondo de lo seleccionado |
| `sobreMorado` | #FFFFFF | #18181B | Texto sobre morado |
| `alza` | #2D6A4F | #7FC9A0 | Variación al alza |
| `baja` | #A3383C | #F0908F | Variación a la baja |

Contraste medido el 2026-11-06 con la fórmula de WCAG: todo texto ≥ 4,7:1 sobre su fondo, en claro y en oscuro.

## Medidas

| Grupo | Valores |
|---|---|
| Espacio | 4 · 8 · 12 · 16 · 20 · 24 · 32 dp |
| Radio | 4 dp (controles, tarjetas, avisos) · 8 dp (botón flotante, hojas) |
| Objetivo táctil | 48 dp mínimo |
| Duración | 150 ms (estado) · 200 ms (hojas y transiciones) |

## Tipografía

| Rol | Familia | Tamaño · peso |
|---|---|---|
| Título de pantalla | ArchivoCondensado | 28 · 800 |
| Título de barra | ArchivoCondensado | 24 · 800 |
| Título de sección | ArchivoCondensado | 20 · 700 |
| Cifra grande | Archivo | 30 · 600 |
| Título de elemento | Archivo | 16 · 600 |
| Cuerpo | Archivo | 16 y 14 · 400 |
| Rótulo | ArchivoCondensado | 12 · 700, mayúsculas |

Todas las cifras usan cifras tabulares.
