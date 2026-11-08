# Plan de implementación: HU-003 · Invitar a una persona y revocar invitaciones

**Rama**: `003-invitar-y-revocar-invitaciones` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

El Administrador crea y revoca invitaciones con dos RPC y ve el resultado en la app. Por capas, cada una con sus pruebas: (1) trigger sobre `invitaciones` que publica el evento `invitacion` en el canal `admin` (solo tabla, id y estado, sin correos ni montos); (2) RPC `public.invitar_usuario(p_email, p_rol, p_cupo_inicial)` y `public.revocar_invitacion(p_id)`: sesión activa y rol, forma de los datos, cuenta existente, duplicado, escritura y auditoría (`cuenta.invitada`, `cuenta.invitacion_revocada`) en una sola transacción; (3) sin Edge Functions: `admin-usuarios` es de HU-010; (4) app: formulario y lista de invitaciones en `lib/features/admin/usuarios/`, con la ruta mínima `/admin/usuarios`; (5) E2E-02 actualizado: invitar por la RPC, entrar con la invitación y comprobar que una revocada, una vencida o una repetida no dejan entrar ni invitar.

## Contexto técnico

SQL/PL/pgSQL en Supabase local con pgTAP (`supabase/tests/database/`); E2E de backend en Deno contra Auth real; Flutter con Riverpod y repositorios en `data/` (docs/05 §9.1). Módulos: M-01, M-02 (docs/17), y M-13 por el evento. Cambios a `docs/`: ninguno de reglas (la historia dice "Documentación a actualizar: ninguna"); solo `docs/17`.

Dependencias ya en `main`: la tabla `invitaciones` y el hook (HU-002), `private.auditar` (HU-107), `private.publicar_evento` y `private.carga_evento` (HU-083), `private.rol_actual` (HU-001) y `private.ahora` (TT-05).

## Revisión de la constitución

Cumple `CLAUDE.md`: funciones `security definer` con `set search_path = ''`; escrituras solo por RPC (la tabla sigue sin `insert`, `update` ni `delete` para la API); la autorización lee `perfiles` con `private.rol_actual()`; la auditoría pasa por `private.auditar`; el evento lleva identificador y estado, nunca correos ni montos; el texto de la app no dice "cuenta corporativa" (docs/13, historial 3.20: invitaciones a cuentas de Google).

## Decisiones de diseño

- **Orden de validación** (docs/03 §4.4): `SESION_INVALIDA` si `rol_actual()` es nulo (incluye al Administrador suspendido con token vigente, CA-7) → `NO_AUTORIZADO` si el rol no es administrador (CA-5) → datos mal formados → `CORREO_YA_REGISTRADO` (CA-3) → `INVITACION_DUPLICADA` (CA-2) → escritura. En `revocar_invitacion`: `NO_EXISTE` y `ESTADO_INVALIDO` (solo se revoca una `pendiente`).
- **Vencimiento**: `invitar_usuario` fija `expira_en = private.ahora() + 7 días` (y `creado_en`, `revocada_en`, con `private.ahora()`), como el hook, para que el reloj de pruebas dé el mismo resultado en ambos. Si el correo tiene una `pendiente` con la fecha pasada, la pasa a `vencida` y crea la nueva (CA-6, docs/08 §5). Dos altas simultáneas del mismo correo: la que pierde el índice único responde `INVITACION_DUPLICADA`.
- **Revocar una pendiente ya pasada de fecha** se permite: sigue en estado `pendiente` (08 §5) y el criterio CA-4 dice "pendiente". Una aceptada, revocada o vencida responde `ESTADO_INVALIDO`.
- **Datos mal formados** (correo sin forma de correo, rol o cupo nulos, cupo negativo): error `22023`, sin código nuevo en 06 §9; la app los evita en el formulario y, si llegaran, muestra el mensaje genérico. El correo se guarda en minúsculas y sin espacios.
- **Cupo inicial**: se guarda tal como llega, sea cual sea el rol; solo se usa si la persona entra como Usuario (04 §6). El formulario lo pide únicamente para ese rol. El máximo por persona (`CUPO_SUPERA_MAXIMO`) no se valida aquí: su parámetro llega con HU-033 y su uso con HU-017 y HU-018.
- **Dominio**: la RPC no compara el dominio con `auth.dominios_permitidos`; lo hace el hook al entrar (04 §5). Queda anotado en el relevo.
- **Evento por trigger**: `after insert or update of estado` sobre `invitaciones` publica `invitacion` con `carga_evento('invitaciones', id, null, estado)`; la tabla no tiene `version` (06 §5.1) y la carga la manda nula. Cubre invitar, revocar, vencer y también la aceptación que hace el trigger de alta, para que la lista de HU-098 se actualice en todos los casos.
- **Auditoría**: `entidad = 'invitaciones'`, id de la invitación. `cuenta.invitada` guarda en `detalle` correo, rol, cupo inicial y vencimiento, y `reemplaza` con el id de la que pasó a `vencida` (11 §4.1 no tiene una acción propia para ese paso). `cuenta.invitacion_revocada` guarda `antes` y `despues` con el estado y en `detalle` el correo y el rol. Una llamada denegada no se audita (EC-012).
- **App**: `FormularioDeInvitacion` y `ListaDeInvitaciones` son widgets reutilizables que HU-098 integrará en su pantalla; `PaginaInvitaciones` los aloja en `/admin/usuarios`. La lista se lee de `invitaciones` (RLS: solo el Administrador) y se vuelve a pedir tras cada acción y con "Actualizar"; escuchar el canal `admin` es de HU-084 y HU-098 (CA-3). Un vencimiento se muestra derivado: `pendiente` con la fecha pasada se ve como "vencida" (08 §5). El sistema no envía correos: la pantalla lo dice con el aviso de 04 §4.1.
- **Ruta mínima**: `/admin/usuarios` en `lib/app/enrutador.dart` y una entrada en la página de inicio visible solo si el token trae `app_rol = administrador`. No son las guardas de HU-006: la seguridad real está en la RPC y la RLS.
- **Diseño**: `/impeccable shape` antes de construir; solo tokens de `lib/app/tema.dart` y componentes de `lib/shared/widgets/`. Si falta un selector de opciones para el rol, se agrega al sistema con su prueba de widget y su entrada en `DESIGN.md` (docs/15 §12).
- **Orden de las migraciones**: se numeran después de las de `main` y de HU-004 (PR #164); antes de la verificación final se renombran con la fecha y hora actuales si `main` trae más nuevas.
