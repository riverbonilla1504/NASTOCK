# HU-116 · Tema, estilos, widgets y fuentes de la v2

| Campo | Valor |
|---|---|
| Épica | [E-13 · Transición desde la v2](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-13` · `M-20` · `prioridad-baja` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que la app nueva conserve la identidad visual de la v2,  
**para** reconocer la plataforma y que todas las pantallas se vean consistentes.

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Reglas

05 §11 · 01 §7

## Criterios de aceptación

- **CA-1** Dados `app_theme.dart`, `app_styles.dart`, los widgets comunes y la fuente Poppins de la v2, cuando se copian, entonces quedan en `lib/app/`, `lib/shared/` y `assets/fonts/`.
- **CA-2** Dada cualquier pantalla nueva, cuando se construye, entonces usa el tema y los widgets comunes.
- **CA-3** Dado el código copiado, cuando corre `flutter analyze`, entonces no deja advertencias.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Copiar `lib/widgets/*`, `lib/config/app_theme.dart`, `lib/config/app_styles.dart` y `assets/fonts/poppins/` desde el repositorio v2.
- [ ] Registrar la fuente en `pubspec.yaml` y aplicar el tema en `lib/app/`.
- [ ] Correr `flutter analyze` y las pruebas de widget que traigan los componentes.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | Se copia dentro del esqueleto de la app. |

## Notas técnicas

No agrega un requisito funcional: es la base visual que usan todas las pantallas.

## Documentación a actualizar

Ninguna.

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
