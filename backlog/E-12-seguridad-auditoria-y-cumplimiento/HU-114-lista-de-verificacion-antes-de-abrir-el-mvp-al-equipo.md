# HU-114 · Lista de verificación antes de abrir el MVP al equipo

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-20, M-17 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-20` · `M-17` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** confirmar punto por punto que la plataforma cumple la lista de seguridad,  
**para** abrir el MVP al equipo sabiendo que no queda nada pendiente.

## Requisitos funcionales

- [FR-222 · Aislamiento verificado por tabla y por función](../requisitos-funcionales/FR-222-aislamiento-verificado-por-tabla-y-por-funcion.md)
- [FR-009 · Prueba de humo tras cada despliegue](../requisitos-funcionales/FR-009-prueba-de-humo-tras-cada-despliegue.md)

## Reglas

11 §10 · 11 §9

## Criterios de aceptación

- **CA-1** Dada la lista de 11 §10, cuando se revisa, entonces cada punto tiene su evidencia: consentimiento de Google en modo Interna, verificación en dos pasos, MFA en las consolas, RLS activo en todas las tablas, JWT de 15 minutos y secretos por entorno.
- **CA-2** Dado el proyecto MVP, cuando corre la prueba de humo, entonces confirma los proveedores reales y el correo con contraseña deshabilitado (CB-91 y CB-92).
- **CA-3** Dado el estado del fondo, cuando se revisa, entonces los interruptores están apagados hasta el primer aporte confirmado y la conciliación está en `ok`.
- **CA-4** Dados los avisos y el simulacro, cuando se revisa, entonces el aviso de privacidad y el de no asesoría están aprobados y el simulacro de restauración está hecho.

## Casos borde

CB-91, CB-92

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Recorrer la lista de 11 §10 y adjuntar la evidencia de cada punto.
- [ ] Corregir lo que no cumpla, con su historia o su error registrado.
- [ ] Dejar constancia de la revisión y de quién la aprobó.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-111 · Avisos de privacidad y de no asesoría](HU-111-avisos-de-privacidad-y-de-no-asesoria.md) | Exige los avisos aprobados. |
| Depende de | [HU-113 · Simulacro de restauración de un respaldo](HU-113-simulacro-de-restauracion-de-un-respaldo.md) | Exige el simulacro de restauración hecho. |
| Depende de | [HU-109 · Aislamiento verificado por tabla y por función](HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) | Exige RLS activo en todas las tablas. |
| Depende de | [HU-110 · Verificación semanal de la cadena de hash](HU-110-verificacion-semanal-de-la-cadena-de-hash.md) | Exige la bitácora verificada. |
| Depende de | [TT-08 · Despliegue continuo al proyecto MVP con prueba de humo](../E-01-cimientos-y-calidad-continua/TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) | Usa la prueba de humo del despliegue. |

## Notas técnicas

Sin notas adicionales.

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
