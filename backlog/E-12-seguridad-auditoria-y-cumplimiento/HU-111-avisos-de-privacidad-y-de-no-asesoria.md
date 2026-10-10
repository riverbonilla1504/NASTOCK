# HU-111 · Avisos de privacidad y de no asesoría

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-01, M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-01` · `M-09` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** conocer y aceptar cómo se usan mis datos y ver claro que las sugerencias no son asesoría financiera,  
**para** usar la plataforma informado de sus límites.

## Requisitos funcionales

- [FR-223 · Aviso de privacidad](../requisitos-funcionales/FR-223-aviso-de-privacidad.md)
- [FR-224 · Aviso de que no es asesoría financiera](../requisitos-funcionales/FR-224-aviso-de-que-no-es-asesoria-financiera.md)

## Reglas

11 §6 · 11 §10 · 07 §14 · RSG-13

## Criterios de aceptación

- **CA-1** Dada una persona en su primer ingreso, cuando entra, entonces ve el aviso de privacidad y debe aceptarlo para continuar.
- **CA-2** Dada una persona que ya lo aceptó, cuando vuelve a entrar, entonces no se le pide otra vez.
- **CA-3** Dado el aviso de privacidad, cuando se lee, entonces declara los datos tratados (nombre y correo corporativo), su finalidad y la transferencia internacional.
- **CA-4** Dada cualquier sugerencia, cuando se muestra su detalle, entonces incluye el aviso de que no constituye asesoría financiera.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: pantalla del aviso de privacidad después del primer ingreso.
- [ ] Registro de la aceptación de cada persona.
- [ ] Revisar que el aviso de no asesoría aparece en el detalle de toda sugerencia.
- [ ] Textos de ambos avisos aprobados por RiTech.
- [ ] Pruebas de widget del flujo de aceptación.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-005 · Ingresar con Google en Android y web](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) | El aviso se presenta tras el primer ingreso. |
| Depende de | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | El aviso de no asesoría vive en el detalle de la sugerencia. |
| Habilita | [HU-114 · Lista de verificación antes de abrir el MVP al equipo](HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) | HU-114: exige los avisos aprobados. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

11 §6 pide aceptar el aviso de privacidad al primer ingreso, pero 06 §5.1 no tiene dónde guardar la aceptación ni 06 §8 la función que la registra. Definirlo en `docs/` antes de implementar. Los textos de ambos avisos los aprueba RiTech (11 §10).

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
