# HU-089 · Elegir qué avisos recibo por push

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-14 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-14` · `prioridad-baja` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** silenciar el push de operaciones y el de alertas de mercado,  
**para** recibir solo los avisos que me interesan.

## Requisitos funcionales

- [FR-195 · Preferencias de notificación](../requisitos-funcionales/FR-195-preferencias-de-notificacion.md)

## Reglas

PM-02 · 09 §5.3

## Criterios de aceptación

- **CA-1** Dada una persona, cuando silencia la categoría Operaciones, entonces deja de recibir push de órdenes ejecutadas, órdenes fallidas y protecciones, pero las sigue viendo en la bandeja.
- **CA-2** Dada la categoría Sugerencias, cuando la persona abre las preferencias, entonces no puede silenciarla: para dejar de recibirlas se pausa la recepción de sugerencias.
- **CA-3** Dado un Administrador, cuando abre las preferencias, entonces no puede silenciar los avisos operativos de administración: integración, descuadre y presupuesto.
- **CA-4** Dada una preferencia cambiada, cuando se guarda, entonces queda en `perfiles.preferencias_push` y aplica desde el siguiente aviso.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función para que cada persona guarde sus propias `preferencias_push`.
- [ ] Encolado del push según la preferencia de la categoría.
- [ ] App: sección de notificaciones en Perfil.
- [ ] Pruebas pgTAP (el push respeta la preferencia y las categorías fijas) y de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-088 · Recibir avisos por push](HU-088-recibir-avisos-por-push.md) | Decide qué notificaciones salen por push. |
| Depende de | [HU-008 · Ver mi perfil](../E-02-identidad-y-acceso/HU-008-ver-mi-perfil.md) | Las preferencias viven en la pantalla de perfil. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

06 §8.1 no define la función con la que cada persona guarda `perfiles.preferencias_push`, y las escrituras de la app solo pueden ir por RPC. Definirla en `docs/` antes de implementar.

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
