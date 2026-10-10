# HU-115 · Motor ×2 teórico de la v2 con sus pruebas

| Campo | Valor |
|---|---|
| Épica | [E-13 · Transición desde la v2](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-05, M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-13` · `M-05` · `M-15` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que la línea ×2 teórico se calcule con el motor ya probado de la v2,  
**para** comparar el fondo con la referencia que RiTech ya conoce.

## Requisitos funcionales

- [FR-227 · Línea ×2 teórico](../requisitos-funcionales/FR-227-linea-x2-teorico.md)

## Reglas

02 §13 · 05 §11 · 01 §7

## Criterios de aceptación

- **CA-1** Dado el repositorio v2, cuando se copia `performance_engine.dart` con su prueba, entonces queda en la app nueva y su prueba pasa en `flutter test`.
- **CA-2** Dada una serie de QQQ, cuando se calcula ×2 teórico, entonces es dos veces la variación acumulada desde el inicio del periodo.
- **CA-3** Dado el código copiado, cuando se revisa, entonces no arrastra los controladores en memoria, el login con contraseña ni la bitácora en memoria de la v2.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Copiar `lib/services/performance_engine.dart` y su prueba desde el repositorio v2.
- [ ] Adaptarlo a la estructura por funcionalidades de la app nueva.
- [ ] Correr `flutter test` y `flutter analyze`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | Se copia dentro del esqueleto de la app. |
| Habilita | [HU-031 · Comparación de QQQ, QLD y ×2 teórico](../E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) | HU-031: usa el motor ×2 copiado de la v2. |

## Notas técnicas

Origen: repositorio v2 `T0m4s1n/ritech-sas-inversiones` (05 §11). Lo usa [HU-031](../E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md).

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
