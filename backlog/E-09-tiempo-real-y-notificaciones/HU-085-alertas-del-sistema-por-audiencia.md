# HU-085 · Alertas del sistema por audiencia

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-18, M-14 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-18` · `M-14` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver las alertas que me corresponden sin que se repitan,  
**para** enterarme de lo importante una sola vez.

## Requisitos funcionales

- [FR-191 · Alertas por audiencia](../requisitos-funcionales/FR-191-alertas-por-audiencia.md)
- [FR-065 · Atributos de los activos](../requisitos-funcionales/FR-065-atributos-de-los-activos.md)

## Reglas

PM-05 · 06 §5.5 · 03 §4.3 · 05 §11

## Criterios de aceptación

- **CA-1** Dada una alerta con audiencia `todos`, cuando cualquier persona activa abre Alertas, entonces la ve; con audiencia `analistas` la ven Analistas y Administradores; con `administradores`, solo los Administradores; y con `usuario`, solo esa persona.
- **CA-2** Dada una alerta activa con una clave de deduplicación, cuando el sistema detecta lo mismo otra vez, entonces no crea otra.
- **CA-3** Dada una alerta resuelta, cuando su causa vuelve a ocurrir, entonces se crea una alerta nueva.
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `alertas`, entonces no recibe las de audiencia `analistas` o `administradores` ni las dirigidas a otra persona.
- **CA-5** Dado un símbolo de la lista blanca que deja de ser negociable, cuando la sincronización diaria lo detecta, entonces se crea una alerta para el Administrador.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tipos `severidad` y `audiencia` y tabla `alertas` (06 §5.5) con el índice único de `clave_dedup` mientras está activa y RLS por audiencia.
- [ ] Migración: función interna para crear y resolver alertas.
- [ ] Conectar la alerta de símbolo no negociable de `calendario-mercado`.
- [ ] App: pantalla Alertas en `lib/features/alertas/`.
- [ ] Pruebas pgTAP (audiencias, deduplicación, rearme y lectura por rol) y prueba de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Las audiencias se resuelven con el rol de `perfiles`. |
| Depende de | [HU-083 · Canales privados de tiempo real](HU-083-canales-privados-de-tiempo-real.md) | Publica el evento `alerta`. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú de los tres roles. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) | Conecta la alerta de símbolo no negociable. |
| Habilita | [HU-013 · Libro contable de doble partida](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) | HU-013: la verificación diaria crea una alerta. |
| Habilita | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | HU-015: alerta al Administrador si el aporte no se confirma. |
| Habilita | [HU-017 · Cupo al aceptar la invitación](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md) | HU-017: crea la alerta `cupo_inicial_no_asignado`. |
| Habilita | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | HU-035: crea la alerta de integración caída. |
| Habilita | [HU-049 · Alertas de contradicción y de mercado](../E-06-ia-contexto-y-decision/HU-049-alertas-de-contradiccion-y-de-mercado.md) | HU-049: guarda y muestra las alertas por audiencia. |
| Habilita | [HU-050 · Presupuesto mensual de IA](../E-06-ia-contexto-y-decision/HU-050-presupuesto-mensual-de-ia.md) | HU-050: alerta al Administrador. |
| Habilita | [HU-078 · Protección virtual en compras fraccionales](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) | HU-078: alerta cuando la protección no está siendo vigilada. |
| Habilita | [HU-086 · Bandeja de notificaciones](HU-086-bandeja-de-notificaciones.md) | HU-086: las alertas generan notificaciones. |
| Habilita | [HU-110 · Verificación semanal de la cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-110-verificacion-semanal-de-la-cadena-de-hash.md) | HU-110: crea la alerta crítica. |

## Notas técnicas

La lógica de avisar una vez y rearmar viene de la v2, trasladada a SQL (05 §11). 14 §4 ubica las alertas de E-09 en R3, pero R2 ya las necesita (CB-11 y CB-15); las alertas de la IA llegan en R3 ([HU-049](../E-06-ia-contexto-y-decision/HU-049-alertas-de-contradiccion-y-de-mercado.md)). El evento `alerta` va solo al canal `supervision` (09 §3): un Usuario se entera en vivo por su notificación `alerta_mercado` (09 §5.1), que llega con [HU-086](HU-086-bandeja-de-notificaciones.md).

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
