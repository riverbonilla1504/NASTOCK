# Plan de implementación: HU-116 · Identidad visual y sistema de diseño

**Rama**: `116-tema-y-estilos-de-la-v2` | **Fecha**: 2026-11-06 | **Especificación**: [spec.md](spec.md)

**Entrada**: especificación de `specs/116-tema-y-estilos-de-la-v2/spec.md`. Historia: [`backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md`](../../backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md) (issue #144). Decisión: D-67.

## Resumen

La app tiene un diseño visual nuevo, hecho con impeccable. Javier aprobó el 2026-11-06 la dirección **Almanaque** con una paleta gris y morado: la interfaz es gris y el color solo lleva datos (morado para las líneas de las gráficas y la marca de "ahora"; verde y rojo apagados solo para la dirección de un precio). La referencia aprobada es `.impeccable/mocks/especimen-almanaque-gris.html`, que no se versiona.

El plan construye, cada capa con sus pruebas: (1) la fuente Archivo como asset; (2) los tokens y el tema claro y oscuro en `lib/app/tema.dart`; (3) los componentes comunes en `lib/shared/widgets/`; (4) el catálogo de componentes, solo en debug o con `MODO_PRUEBAS`; (5) `DESIGN.md` y `.impeccable/design.json`, escritos por impeccable a partir de lo construido, con `audit` y `polish`.

## Contexto técnico

**Lenguaje/Versión**: Dart y Flutter 3.47 (los de TT-04).

**Dependencias principales**: Material 3 de Flutter, `flutter_riverpod` y `go_router` (ya en `pubspec.yaml`). Ningún paquete nuevo: los íconos son los de Material que trae Flutter y la gráfica se dibuja con `CustomPainter`.

**Almacenamiento**: ninguno.

**Pruebas**: `flutter test` con pruebas de widget en `test/shared/widgets/` y `test/app/`; `flutter analyze` sin advertencias.

**Plataforma de destino**: app Flutter para Android y web (`com.ritech.inversiones`).

**Tipo de proyecto**: solo app. Sin base de datos, sin Edge Functions y sin escenario E2E propio (15 §4).

**Metas de rendimiento**: el tema se construye una sola vez por arranque; los componentes no animan nada más que el cambio de estado (150–200 ms).

**Restricciones**: WCAG 2.2 AA (`PRODUCT.md`): contraste de 4,5:1 en texto y 3:1 en líneas de gráfica, objetivos táctiles de 48 dp, texto que escala y ningún estado que dependa solo del color. Los textos de error salen de `lib/core/errores/` (06 §9). Ninguna fuente ni recurso se carga de un servicio externo.

**Escala/Alcance**: un tema, unos quince componentes, una página de catálogo.

## Revisión de la constitución (Constitution Check)

| Principio o invariante | Cumple | Cómo |
|---|---|---|
| I · `docs/` es la fuente de verdad | Sí | Lo visual vive en `DESIGN.md` por D-67; los textos, los estados de una acción (08 §9.3), el dato desactualizado (08 §9.4) y los mensajes de error (06 §9) salen de `docs/`. |
| II · Documentación primero | Sí | D-67 quedó en `docs/` antes de construir (05 §9, §11, §12 · 14 §4.1 · 15 §12 · 13). |
| IV · Investigación acotada | Sí | Solo M-20 (`lib/app/`, `lib/shared/`, `lib/core/formato/`, `lib/core/errores/`). |
| VI · Verificación de punta a punta | Sí | `scripts/verificar.sh` completo antes de terminar. Las pruebas de `MensajeDeError` y de la app de TT-04 siguen pasando sin relajarse. |
| VII · Alcance y costo | Sí | Fuente con licencia OFL; ningún paquete ni servicio de pago. |
| Invariante 6 (sin llaves) | Sí | No se usa ninguna llave. |

Sin violaciones: no hay tabla de complejidad.

## Estructura del proyecto

### Documentación de esta historia

```text
specs/116-tema-y-estilos-de-la-v2/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # Decisiones de diseño (Fase 0)
├── data-model.md        # Los tokens (Fase 1)
├── quickstart.md        # Cómo comprobar la historia (Fase 1)
├── contracts/
│   └── componentes.md   # La interfaz pública de cada componente (Fase 1)
├── checklists/
└── tasks.md             # /speckit-tasks
```

### Código fuente

```text
assets/fonts/archivo/          # 7 instancias de Archivo + OFL.txt + LEEME.md (origen)
pubspec.yaml                   # + fuentes Archivo y ArchivoCondensado
DESIGN.md                      # Sistema visual (impeccable document)
PRODUCT.md                     # Contexto de producto (ya escrito)
.impeccable/design.json        # Tokens para impeccable (lo escribe document)
.impeccable/surfaces/          # Contrato de dirección (surface brief)
lib/app/
├── tema.dart                  # Tokens (ThemeExtension) y temas claro y oscuro
├── aplicacion.dart            # + darkTheme y themeMode
├── enrutador.dart             # + /catalogo solo en debug o con MODO_PRUEBAS
└── catalogo/pagina_catalogo.dart
lib/core/formato/formato_porcentaje.dart
lib/shared/widgets/            # botones, tarjeta, campo, avisos, estados, cifras,
                               # chip, cotización, gráfica, calendario, franja
test/shared/widgets/           # una prueba por componente
test/app/                      # tema y ruta del catálogo
test/core/formato/formato_porcentaje_test.dart
docs/17-mapa-de-modulos.md     # M-20: rutas nuevas
```

## Capas y orden

| # | Capa | Entrega | Cubre | Pruebas |
|---|---|---|---|---|
| 1 | Fuente | `assets/fonts/archivo/`, `pubspec.yaml` | CA-12 | `flutter analyze`; la fuente carga en Chrome y en el emulador |
| 2 | Tokens y tema | `lib/app/tema.dart`, `aplicacion.dart` | CA-6 | `test/app/tema_test.dart`: tokens en claro y oscuro, contraste mínimo de los pares de texto |
| 3 | Componentes | `lib/shared/widgets/*` | CA-7, CA-8, CA-9 | Una prueba de widget por componente; `MensajeDeError` conserva sus pruebas |
| 4 | Catálogo | `lib/app/catalogo/`, ruta `/catalogo` | CA-10 | `test/app/catalogo_test.dart`: la ruta existe con el permiso y no existe sin él |
| 5 | Documentación visual | `DESIGN.md`, `.impeccable/design.json` | CA-4, CA-5, CA-11 | `/impeccable audit` y `polish`; capturas en Chrome y en el emulador |

## Riesgos y puntos abiertos

- **Otras ramas usan `MensajeDeError`**: se conserva su nombre y su constructor; solo cambia cómo se dibuja.
- **Festivos y medias jornadas**: el calendario los recibe como datos. Los trae el calendario del broker (RN-41), que construye HU-027; aquí solo se dibujan.
- **Fuente variable**: Flutter no aplica de forma fiable el eje de peso de una fuente variable con `fontWeight` en todas las plataformas; por eso se usan instancias estáticas (R-1 de [research.md](research.md)).
