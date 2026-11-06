# HU-116 · Identidad visual y sistema de diseño

| Campo | Valor |
|---|---|
| Épica | [E-13 · Transición desde la v2](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| MVP corto | Sí, con otro alcance (D-67) |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-13` · `M-20` · `prioridad-baja` |

## MVP corto

Entra con **otro alcance** ([docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)). Por D-67 ya no copia la interfaz de la v2: construye con el plugin impeccable un diseño visual nuevo para la app. La v2 solo sirve como referencia de contenido (qué pantallas, datos y flujos había) y como antirreferencia visual: no se conservan su paleta, sus widgets ni la fuente Poppins. Los criterios CA-1 a CA-3, que describían la copia, se retiran y los reemplazan CA-4 a CA-12.

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que la app tenga una identidad visual propia,  
**para** reconocer la plataforma y que todas las pantallas se vean consistentes.

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Reglas

05 §9 · 05 §11 · 15 §12 · 01 §7 · D-67

## Criterios de aceptación

- ~~**CA-1**~~ ~~**CA-2**~~ ~~**CA-3**~~ Retirados por D-67: describían la copia de `app_theme.dart`, `app_styles.dart`, los widgets y la fuente de la v2.
- **CA-4** Dados `docs/01` a `docs/04`, cuando se escribe `PRODUCT.md` con impeccable, entonces describe los usuarios, el propósito y el tono sin agregar nada que no esté en esos documentos.
- **CA-5** Dada la dirección visual aprobada por el equipo, cuando se documenta, entonces `DESIGN.md`, en la raíz, define los tokens (color, tipografía, espaciado, forma y elevación), los componentes, el movimiento y el tono visual, y `.impeccable/config.json` queda en el repositorio.
- **CA-6** Dado el tema de `lib/app/tema.dart`, cuando se construye cualquier pantalla, entonces toma colores, tipografía y medidas de los tokens de `DESIGN.md`.
- **CA-7** Dados los componentes de `lib/shared/widgets/` (botón primario y secundario, tarjeta, campo, aviso en línea, aviso temporal, estados vacío, de carga y de error, selector de fecha y calendario, cifra en USD con variación y chip de estado), cuando se usan, entonces cada uno tiene su prueba de widget.
- **CA-8** Dado un aviso o un estado (información, éxito, advertencia, error o dato desactualizado), cuando se muestra, entonces su significado se entiende también sin color, por su texto y su ícono o su forma.
- **CA-9** Dado un error capturado, cuando lo muestra un componente del sistema, entonces el texto pasa por la traducción de errores de `lib/core/errores/` y nunca muestra el texto crudo de la excepción.
- **CA-10** Dada la app en modo debug o con `MODO_PRUEBAS`, cuando se abre el catálogo de componentes, entonces muestra todos los componentes juntos; en una compilación sin debug y sin `MODO_PRUEBAS`, el catálogo no existe.
- **CA-11** Dado el sistema terminado, cuando corren `/impeccable audit` y `/impeccable polish`, entonces lo que encuentran queda corregido y revisado en Chrome y en el emulador de Android.
- **CA-12** Dadas las fuentes y el código del sistema, cuando corren `flutter analyze` y `flutter test`, entonces no dejan advertencias ni fallos, y las fuentes están en `assets/fonts/` con su licencia libre, sin cargarse de un servicio externo.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Contexto de impeccable: `PRODUCT.md` desde `docs/01` a `docs/04`, y `.impeccable/config.json`.
- [ ] Revisar la v2 como referencia de contenido y antirreferencia (fuera del repositorio) y proponer una dirección visual nueva: paleta, tipografía, densidad, forma, movimiento y voz visual, con ejemplos de aviso, calendario, tarjeta de cotización y botones. Aprobación del equipo antes de construir.
- [ ] Tokens y tema en `lib/app/tema.dart`; fuentes en `assets/fonts/` registradas en `pubspec.yaml`.
- [ ] Componentes en `lib/shared/widgets/`, con sus pruebas de widget. Reemplazar `MensajeDeError` si el sistema lo cubre, sin romper la traducción de errores.
- [ ] Catálogo de componentes solo en debug o con `MODO_PRUEBAS`.
- [ ] `/impeccable document` para `DESIGN.md`; `/impeccable audit` y `/impeccable polish`; capturas en Chrome y en el emulador.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | Se construye dentro del esqueleto de la app. |

## Notas técnicas

No agrega un requisito funcional: es la base visual que usan todas las pantallas. `DESIGN.md` manda en lo visual y `docs/` en todo lo demás (D-67).

## Documentación a actualizar

`docs/05` §9, §11 y §12 · `docs/14` §2 y §4.1 · `docs/15` §12 · `docs/13` (D-67 e historial) · `docs/17` (M-20) · `CLAUDE.md`.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde
