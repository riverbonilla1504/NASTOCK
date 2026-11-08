---
description: "Tareas de HU-033 · Parámetros configurables con rango e historial"
---

# Tareas: HU-033 · Parámetros configurables con rango e historial

**Entrada**: [plan.md](plan.md), [spec.md](spec.md).

- [ ] T001 [US1] Migración `*_catalogo_de_parametros.sql`: inserta en `public.parametros` el catálogo de `docs/02` §10 (clave, valor, tipo, minimo, maximo, descripcion) sin tocar `auth.dominios_permitidos` ni `auth.proveedores_permitidos`; crea `public.parametros_historial` (`id bigserial`, `clave`, `valor_anterior`, `valor_nuevo`, `cambiado_por`, `cambiado_en`, `motivo`) con RLS, lectura solo del Administrador activo y sin escritura para la API
- [ ] T002 [US1] Migración `*_actualizar_parametro.sql`: `public.actualizar_parametro(clave, valor, motivo)` (`security definer`, `search_path` vacío, solo `administrador` por `private.rol_actual()`, si no `NO_AUTORIZADO`); valida tipo y rango (`PARAMETRO_FUERA_DE_RANGO`), motivo no vacío, clave existente (`NO_EXISTE`); guarda historial, sube `version`, `private.auditar` `parametro.cambiado` y `private.publicar_evento('admin','parametro', private.carga_evento(...))`
- [ ] T003 [US1] Misma migración: clave `reparto` con `{pct_reserva, pct_arriesgadas, pct_usuarios}` en una sola operación que suma 100; `reparto.pct_*` suelto responde `PARAMETRO_FUERA_DE_RANGO` (CB-78); no toca el libro (CB-75)
- [ ] T004 [US1] Migración `*_margenes_desde_parametros.sql`: `create or replace` de `private.margenes_de_compra()` leyendo `mercado.minutos_tras_apertura` y `mercado.minutos_antes_cierre` de `parametros`
- [ ] T005 [US1] pgTAP `10_politicas_parametros_test.sql` (CA-1 a CA-5): cambio con historial, auditoría y evento sin valores; fuera de rango y de tipo; reparto suma 100 y suelto; reparto no mueve saldos; permisos (Usuario y Analista `NO_AUTORIZADO`, leen `parametros`, no `parametros_historial`); catálogo completo; `margenes_de_compra` sigue en 5 y 15 y refleja un cambio; las pruebas existentes de `05_calendario_y_horario_test.sql` siguen pasando
- [ ] T006 `docs/17` (M-08 y M-07) actualizado; `scripts/verificar.sh` completo en verde
