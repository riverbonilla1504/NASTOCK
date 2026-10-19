# TT-09 · Mantenimiento: ping diario, respaldo cifrado y prueba real semanal

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Media |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-media` |

## Qué hay que hacer y por qué

Activar `mantenimiento.yml`: el `ping()` diario que evita la pausa del proyecto gratuito, el respaldo diario cifrado (el plan gratuito de Supabase no respalda) y la prueba real semanal de los proveedores.

## Documentación fuente

15 §5 · 15 §6 · 11 §7 · 05 §3.4 · D-55

## Requisitos funcionales

- [FR-008 · Latido del proyecto](../requisitos-funcionales/FR-008-latido-del-proyecto.md)
- [FR-010 · Respaldo diario cifrado](../requisitos-funcionales/FR-010-respaldo-diario-cifrado.md)
- [FR-011 · Prueba real semanal de proveedores](../requisitos-funcionales/FR-011-prueba-real-semanal-de-proveedores.md)

## Criterio de terminado

- [ ] El flujo diario llama a `ping()` del proyecto MVP y, si no responde, falla y avisa (CB-93).
- [ ] El flujo diario genera `supabase db dump`, lo cifra con GPG con `RESPALDO_CLAVE_GPG` y lo deja como artefacto 7 días; el archivo no se lee sin la clave.
- [ ] El flujo semanal hace una llamada real mínima a Alpaca paper (solo lectura), a DeepSeek y a JEV, con un costo menor a USD 0,01.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] Cargar `SUPABASE_DB_URL` y `RESPALDO_CLAVE_GPG` y guardar una copia de la clave fuera de GitHub.
- [ ] Ejecutar `mantenimiento.yml` a mano y revisar el artefacto cifrado.
- [ ] Descifrar un respaldo en local para comprobar que sirve.
- [ ] Activar la prueba semanal de cada proveedor cuando exista su adaptador real.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-08 · Despliegue continuo al proyecto MVP con prueba de humo](TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) | Necesita el proyecto MVP desplegado. |
| Habilita | [HU-113 · Simulacro de restauración de un respaldo](../E-12-seguridad-auditoria-y-cumplimiento/HU-113-simulacro-de-restauracion-de-un-respaldo.md) | HU-113: usa el respaldo cifrado diario. |
