---
description: "Tareas de HU-002 · Alta solo con invitación vigente"
---

# Tareas: HU-002 · Alta solo con invitación vigente

**Entrada**: [plan.md](plan.md), [spec.md](spec.md).

- [x] T001 Docs: `cuenta.correo_cambiado` (docs/11 §4.1), dominios vacíos (docs/02 §13), historial 3.19 (docs/13 §4)
- [x] T002 Migración `20261107150000_invitaciones.sql`: tipo `estado_invitacion`, tabla, índice único, llave foránea de `perfiles`, RLS
- [x] T003 Migración `20261107150002_parametros.sql`: tabla, RLS y las dos claves
- [x] T004 Migración `20261107150004_hook_antes_de_crear_usuario.sql`: `private.error_auth`, hook y permisos; registro en `config.toml`
- [x] T005 Migración `20261107150006_al_crear_usuario.sql`: triggers de alta y de sincronización del correo
- [x] T006 `seed.sql`: usuarios de prueba por rol, dominio `prueba.local` y proveedor `email`
- [x] T007 pgTAP `08_auth_alta_con_invitacion_test.sql` (CA-1 a CA-6)
- [x] T008 Helper `crearUsuarioDePrueba` por invitación; E2E-02 `02_alta_con_invitacion_test.ts` (CA-1 a CA-5, CA-7)
- [x] T009 `docs/17` actualizado; `scripts/verificar.sh` completo en verde
