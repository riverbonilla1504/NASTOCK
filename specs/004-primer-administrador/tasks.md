---
description: "Tareas de HU-004 · Primer administrador por configuración de despliegue"
---

# Tareas: HU-004 · Primer administrador por configuración de despliegue

**Entrada**: [plan.md](plan.md), [spec.md](spec.md).

- [x] T001 Docs y backlog: Gmail, Q-08, Q-22, S1, mensajes del hook y sin pista `hd` (historial 3.20); mecanismo de `ADMIN_INICIAL_EMAIL` en 04 §9, 16 §4.1 y 05 §10 (historial 3.21); historias y requisitos del backlog que decían Workspace
- [x] T002 Migración `*_mensajes_del_hook.sql`: `create or replace` de `private.antes_de_crear_usuario` con los dos mensajes nuevos; actualizar `08_auth_alta_con_invitacion_test.sql` y `02_alta_con_invitacion_test.ts`
- [x] T003 Migración `*_primer_administrador.sql`: `private.cargar_dominio_inicial()` y `private.crear_invitacion_inicial()` (permisos solo del dueño) y su llamada única
- [x] T004 pgTAP `09_primer_administrador_test.sql` (CA-1 a CA-3): crea con el secreto, en minúsculas y a 7 días con `creada_por` nulo; no crea con un administrador, sin secreto, con una pendiente vigente ni al repetirla; reemite si la pendiente venció; rechaza un correo mal formado o de un dominio no permitido; deja el dominio solo si estaba vacío; la persona entra por el hook y el trigger y queda como Administrador activo; bitácora; permisos
- [x] T005 `supabase/config.toml`: sección `[db.vault]` con `admin_inicial_email = "env(ADMIN_INICIAL_EMAIL)"`; comprobar que `supabase start` y `db reset` siguen funcionando sin la variable
- [x] T006 `despliegue.yml`: paso que falla si falta `ADMIN_INICIAL_EMAIL` y el secreto pasado a `supabase db push`
- [x] T007 Ensayo del camino de la nube en local (`db push --db-url` con la variable) y nota en el relevo
- [x] T008 `scripts/verificar.sh`, `ci.yml` y `docs/15` §2: CA-4, sin `admin@admin.com` ni inserciones con contraseña en migraciones, funciones, app ni flujos
- [x] T009 `.env.example`: aviso de que `ADMIN_INICIAL_EMAIL` es un secreto de GitHub y no va en `.env`
- [x] T010 `docs/17` (M-01) actualizado; `scripts/verificar.sh` completo en verde
