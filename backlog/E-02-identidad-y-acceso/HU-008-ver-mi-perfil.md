# HU-008 · Ver mi perfil

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-02` · `prioridad-baja` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver mi nombre, mi correo, mi rol y el estado de mi cuenta,  
**para** confirmar con qué cuenta y con qué permisos estoy usando la plataforma.

## Requisitos funcionales

- [FR-024 · Consulta del perfil propio](../requisitos-funcionales/FR-024-consulta-del-perfil-propio.md)

## Reglas

PM-02 · RN-58 · 11 §6

## Criterios de aceptación

- **CA-1** Dada una persona con sesión, cuando abre Perfil, entonces ve su nombre, su correo, su rol y su estado.
- **CA-2** Dado el perfil, cuando la persona busca editar el correo, entonces no existe esa opción: el correo es su identidad de Google.
- **CA-3** Dado un Usuario, cuando consulta `perfiles` por la API, entonces solo recibe su propia fila.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: pantalla Perfil (parte de "Perfil y notificaciones" de 03 §3) con los datos de `perfilProvider`.
- [ ] App: texto que indica que el nombre se corrige en Google Workspace (11 §6).
- [ ] Pruebas de widget de la pantalla.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-006 · Navegación y guardas según el rol](HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú por rol. |
| Habilita | [HU-068 · Pausar la recepción de sugerencias](../E-07-sugerencias-y-decisiones/HU-068-pausar-la-recepcion-de-sugerencias.md) | HU-068: el interruptor vive en la pantalla de perfil. |
| Habilita | [HU-089 · Elegir qué avisos recibo por push](../E-09-tiempo-real-y-notificaciones/HU-089-elegir-que-avisos-recibo-por-push.md) | HU-089: las preferencias viven en la pantalla de perfil. |

## Notas técnicas

Las preferencias de notificación de esta pantalla llegan con [HU-089](../E-09-tiempo-real-y-notificaciones/HU-089-elegir-que-avisos-recibo-por-push.md).

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
