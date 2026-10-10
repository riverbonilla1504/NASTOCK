# HU-061 · Mis sugerencias: bandeja y detalle con explicación

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** ver mis sugerencias vivas con su tiempo restante y abrir el detalle de cada una,  
**para** entender qué me proponen y por qué antes de decidir.

## Requisitos funcionales

- [FR-140 · Bandeja de sugerencias del Usuario](../requisitos-funcionales/FR-140-bandeja-de-sugerencias-del-usuario.md)
- [FR-141 · Detalle de la sugerencia](../requisitos-funcionales/FR-141-detalle-de-la-sugerencia.md)
- [FR-224 · Aviso de que no es asesoría financiera](../requisitos-funcionales/FR-224-aviso-de-que-no-es-asesoria-financiera.md)

## Reglas

PM-11 · RN-22 · 07 §14 · 03 §3 · 08 §9

## Criterios de aceptación

- **CA-1** Dado un Usuario con sugerencias vivas, cuando abre Mis sugerencias, entonces ve cada una con su cuenta regresiva y el estado del precio: vigente, se aleja o fuera de banda.
- **CA-2** Dada una sugerencia, cuando abre su detalle, entonces ve exactamente lo que se va a comprar o vender ("1 acción de QLD ≈ USD 110,00"), la explicación, el stop y el objetivo en precios ("si baja a 103,40 se vende sola"), el nivel de riesgo y el vencimiento.
- **CA-3** Dado el detalle, cuando se muestra, entonces incluye el aviso fijo de que la sugerencia no constituye asesoría financiera.
- **CA-4** Dada una sugerencia nueva o un cambio de estado, cuando ocurre, entonces la bandeja se actualiza en vivo con el evento `sugerencia`.
- **CA-5** (aislamiento) Dado un Usuario, cuando consulta `sugerencias`, entonces solo ve las suyas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-08.

## Tareas

- [ ] App: `lib/features/sugerencias/` con `bandejaSugerenciasProvider` (foto y eventos) y `sugerenciaProvider(id)`.
- [ ] App: detalle con las piezas de 07 §14: qué, por qué ganó, qué la frena, contexto con titulares, advertencias, protección, riesgo y tiempo.
- [ ] App: cuenta regresiva con el reloj corregido y estado del precio frente a la banda.
- [ ] App: aviso fijo de 07 §14, punto 7.
- [ ] Pruebas de widget de la bandeja y del detalle.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | Muestra las sugerencias que recibe el cupo. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Se actualiza con el patrón foto y eventos. |
| Depende de | [HU-032 · Aviso de dato desactualizado](../E-04-datos-de-mercado/HU-032-aviso-de-dato-desactualizado.md) | Deshabilita la decisión con el dato desactualizado. |
| Habilita | [HU-062 · Aprobar una sugerencia de mi cupo](HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | HU-062: se aprueba desde el detalle de la sugerencia. |
| Habilita | [HU-063 · Rechazar una sugerencia con motivo](HU-063-rechazar-una-sugerencia-con-motivo.md) | HU-063: se rechaza desde el detalle de la sugerencia. |
| Habilita | [HU-064 · Bandeja de riesgo del Analista](HU-064-bandeja-de-riesgo-del-analista.md) | HU-064: reutiliza el detalle con explicación. |
| Habilita | [HU-090 · Abrir la app desde la notificación](../E-09-tiempo-real-y-notificaciones/HU-090-abrir-la-app-desde-la-notificacion.md) | HU-090: lleva al detalle de la sugerencia. |
| Habilita | [HU-111 · Avisos de privacidad y de no asesoría](../E-12-seguridad-auditoria-y-cumplimiento/HU-111-avisos-de-privacidad-y-de-no-asesoria.md) | HU-111: el aviso de no asesoría vive en el detalle de la sugerencia. |

## Notas técnicas

Los botones Aprobar y Rechazar están en [HU-062](HU-062-aprobar-una-sugerencia-de-mi-cupo.md) y [HU-063](HU-063-rechazar-una-sugerencia-con-motivo.md).

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
