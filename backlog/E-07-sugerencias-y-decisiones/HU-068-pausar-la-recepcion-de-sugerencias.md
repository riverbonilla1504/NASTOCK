# HU-068 · Pausar la recepción de sugerencias

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-09, M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-02` · `prioridad-baja` |

## Historia

**Como** Usuario,  
**quiero** pausar la recepción de sugerencias cuando no voy a estar disponible,  
**para** no recibir avisos que no podré atender, por ejemplo en vacaciones.

## Requisitos funcionales

- [FR-154 · Pausa de la recepción de sugerencias](../requisitos-funcionales/FR-154-pausa-de-la-recepcion-de-sugerencias.md)

## Reglas

PM-15 · 07 §7.3 · 09 §5.3

## Criterios de aceptación

- **CA-1** Dado un Usuario, cuando pausa la recepción, entonces `recibe_sugerencias` queda en falso y no se crean sugerencias nuevas para su cupo.
- **CA-2** (caso borde) CB-27: Dado un Usuario en pausa con posiciones, cuando el precio toca un stop, entonces la protección se ejecuta igual.
- **CA-3** Dado un Usuario en pausa, cuando reanuda, entonces vuelve a recibir sugerencias desde el siguiente ciclo.
- **CA-4** (permiso) Dado un Usuario, cuando llama `pausar_sugerencias`, entonces solo cambia su propio perfil.

## Casos borde

CB-27

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `pausar_sugerencias(pausar)` sobre `perfiles.recibe_sugerencias`, con el evento `perfil_actualizado`.
- [ ] App: interruptor en Perfil y aviso visible de que la recepción está en pausa.
- [ ] Pruebas pgTAP (la pausa excluye el cupo del reparto) y prueba de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | El reparto respeta la pausa. |
| Depende de | [HU-008 · Ver mi perfil](../E-02-identidad-y-acceso/HU-008-ver-mi-perfil.md) | El interruptor vive en la pantalla de perfil. |

## Notas técnicas

Las sugerencias que ya estaban vivas al pausar siguen hasta decidirse o vencer. El push de sugerencias no se silencia de otra forma (09 §5.3).

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
