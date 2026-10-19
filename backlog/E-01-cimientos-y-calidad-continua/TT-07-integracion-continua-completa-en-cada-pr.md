# TT-07 · Integración continua completa en cada PR

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-alta` |

## Qué hay que hacer y por qué

Comprobar que `ci.yml` ejecuta en cada PR todos sus trabajos ya con código real: documentación, arquitectura, app, backend y E2E. Es la garantía de que nada se integra roto.

## Documentación fuente

15 §1 · 15 §5 · 15 §6 · 15 §7 · 15 §10 · 05 §10.2 · 11 §9

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Criterio de terminado

- [ ] Un PR de prueba dispara `detectar`, `documentacion`, `arquitectura`, `app`, `backend` y `e2e`, y todos terminan en verde.
- [ ] Un PR que rompe una prueba deja CI en rojo y no se integra (con protección de rama si el repositorio la admite, Q-18).
- [ ] El trabajo `arquitectura` falla si `agente`, `contexto-ia` u `opinion-ia` importan `_shared/broker/`, si la app menciona la llave secreta o si hay un `.env` versionado.
- [ ] El escáner de secretos y de dependencias corre en cada PR.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] Abrir un PR borrador y revisar cada trabajo de `ci.yml` con el código de las tareas técnicas anteriores.
- [ ] Ajustar en el flujo las versiones de Flutter, Deno y Supabase CLI si hace falta.
- [ ] Revisar que `supabase db lint` no deja advertencias.
- [ ] Confirmar que las ejecuciones viejas de la misma rama se cancelan (`concurrency`).
- [ ] Anotar en `docs/errores-conocidos.md` cualquier problema de CI que cueste más de un intento.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-06 · Arnés E2E de backend y de la app](TT-06-arnes-e2e-de-backend-y-de-la-app.md) | CI ejecuta el E2E de backend y de la app. |
| Habilita | [TT-08 · Despliegue continuo al proyecto MVP con prueba de humo](TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) | TT-08: el despliegue solo corre tras CI en verde. |
| Habilita | [HU-109 · Aislamiento verificado por tabla y por función](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) | HU-109: la suite corre en cada PR. |
