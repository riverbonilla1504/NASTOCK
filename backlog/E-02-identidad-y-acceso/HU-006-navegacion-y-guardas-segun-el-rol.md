# HU-006 · Navegación y guardas según el rol

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-01, M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `M-02` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver solo los menús y las pantallas de mi rol,  
**para** encontrar rápido lo que me toca y no llegar a pantallas que no puedo usar.

## Requisitos funcionales

- [FR-021 · Navegación según el rol](../requisitos-funcionales/FR-021-navegacion-segun-el-rol.md)

## Reglas

03 §3 · 05 §9.3 · 03 §1 (principio 3)

## Criterios de aceptación

- **CA-1** Dados un Usuario, un Analista y un Administrador con sesión, cuando abren la app, entonces cada uno ve el menú de su rol según 03 §3.
- **CA-2** Dado un Usuario, cuando abre un enlace a `/admin/...` o a `/riesgo/...`, entonces el enrutador lo lleva a `/inicio`.
- **CA-3** Dada una persona sin sesión, cuando abre cualquier ruta, entonces llega a `/ingreso`; y con `app_estado` distinto de activo, a `/cuenta-suspendida`.
- **CA-4** Dado un Administrador, cuando abre `/riesgo/...`, entonces entra en modo de solo lectura.

## Casos borde

—

## Escenario E2E

E2E-01 (nuevo)

## Tareas

- [ ] App: enrutador `go_router` en `lib/app/` con las guardas de 05 §9.3 a partir de `perfilProvider`.
- [ ] App: menú principal por rol, pantallas de inicio y de cuenta suspendida y marcadores de las secciones que aún no existen.
- [ ] Pruebas de widget de las guardas para cada rol.
- [ ] E2E-01 de la app: cada rol ve su navegación y las rutas prohibidas redirigen.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-005 · Ingresar con Google en Android y web](HU-005-ingresar-con-google-en-android-y-web.md) | Necesita una sesión con rol. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-01. |
| Habilita | [HU-008 · Ver mi perfil](HU-008-ver-mi-perfil.md) | HU-008: la pantalla cuelga del menú por rol. |
| Habilita | [HU-019 · Ver mi cupo](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) | HU-019: la pantalla cuelga del menú del Usuario. |
| Habilita | [HU-020 · Ver el resumen del fondo por bolsillos](../E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md) | HU-020: la pantalla cuelga del menú de los tres roles. |
| Habilita | [HU-030 · Pantalla de mercado en vivo](../E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md) | HU-030: es la pantalla de inicio de los tres roles. |
| Habilita | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](../E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | HU-048: la pantalla cuelga del menú de los tres roles. |
| Habilita | [HU-057 · Desempeño y calibración de la IA](../E-06-ia-contexto-y-decision/HU-057-desempeno-y-calibracion-de-la-ia.md) | HU-057: la pantalla cuelga del menú de Analista y Administrador. |
| Habilita | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | HU-085: la pantalla cuelga del menú de los tres roles. |
| Habilita | [HU-097 · Sección de Administración y guía de primeros pasos](../E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | HU-097: cuelga de la navegación por rol. |

## Notas técnicas

La navegación es experiencia de uso; la seguridad real está en RLS y en las funciones (03 §4).

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
