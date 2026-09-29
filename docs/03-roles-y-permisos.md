# 03 · Roles y permisos

## 1. Los tres roles

| | **Usuario** | **Analista** | **Administrador** |
|---|---|---|---|
| Quién es | Empleado de RiTech | Personal de inversiones | Gerencia / tesorería |
| Misión | Hacer crecer **su cupo** | Controlar el **riesgo** del fondo | Gobernar el **dinero**, las **cuentas** y las **reglas** |
| Decide sobre | Sugerencias y órdenes de su cupo | Sugerencias de Arriesgadas y ventas de liquidación | Aportes, retiros, cupos, rebalanceos, parámetros, cuentas |
| Nunca puede | Ver ni tocar cupos ajenos | Mover dinero entre subcuentas, gestionar cuentas, cambiar parámetros | **Aprobar operaciones de mercado** (compras o ventas) |

### Principios

1. **Un rol por persona** (D-01). No existen combinaciones. Quien administra
   el dinero no aprueba riesgo, y quien aprueba riesgo no mueve dinero.
2. **Mínimo privilegio.** Cada rol ve lo que necesita para su función y nada
   más.
3. **Los permisos se aplican en el servidor.** La app oculta botones para
   que la experiencia sea limpia, pero la seguridad real está en la base de
   datos (RLS y funciones). Un cliente modificado no gana permisos.
4. **Todo cambio de permisos se audita.**

---

## 2. Matriz de permisos

✅ puede · 👁 solo lectura · ❌ no puede · *propio* = solo sobre lo suyo

### Cuenta y mercado

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-01 | Iniciar sesión con Google (si fue invitado y está activo) | ✅ | ✅ | ✅ |
| PM-02 | Ver su perfil y preferencias de notificación | ✅ | ✅ | ✅ |
| PM-03 | Registrar su dispositivo para push | ✅ | ✅ | ✅ |
| PM-04 | Ver dashboard de mercado: cotizaciones, QQQ vs QLD vs ×2 teórico, estado del mercado | ✅ | ✅ | ✅ |
| PM-05 | Ver alertas informativas dirigidas a todos | ✅ | ✅ | ✅ |
| PM-06 | Ver parámetros vigentes (vencimientos, límites) | 👁 | 👁 | ✅ |
| PM-07 | Ver la lista blanca | 👁 | 👁 | ✅ |

### Su cupo (bolsillo Usuarios)

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-10 | Ver su cupo: efectivo, disponible, posiciones, resultado, historial | ✅ *propio* | 👁 todos | 👁 todos |
| PM-11 | Recibir y **aprobar / rechazar** sugerencias de su cupo | ✅ *propio* | ❌ | ❌ |
| PM-12 | Crear **orden manual** de compra o venta en su cupo (con opinión de la IA) | ✅ *propio* | ❌ | ❌ |
| PM-13 | Cancelar una orden propia aún no llenada | ✅ *propio* | ❌ | ❌ |
| PM-14 | Ajustar stop / objetivo de una posición propia (dentro de RR-08) | ✅ *propio* | ❌ | ❌ |
| PM-15 | Pausar la recepción de sugerencias (vacaciones) | ✅ *propio* | — | — |

### Bolsillo Arriesgadas

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-20 | Ver la bandeja de sugerencias de Arriesgadas | ❌ | ✅ | 👁 |
| PM-21 | **Aprobar / rechazar** sugerencias de Arriesgadas (primera o segunda aprobación) | ❌ | ✅ | ❌ |
| PM-22 | Solicitar un análisis bajo demanda a la IA sobre un símbolo de la lista blanca de Arriesgadas | ❌ | ✅ | ❌ |
| PM-23 | Ajustar stop / objetivo de una posición de Arriesgadas (dentro de RR-08) | ❌ | ✅ | ❌ |
| PM-24 | Aprobar / rechazar ventas de **liquidación** de cupos | ❌ | ✅ | ❌ |

### Supervisión y reportes

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-30 | Ver resumen **agregado** del fondo (patrimonio y peso por bolsillo) | 👁 | 👁 | 👁 |
| PM-31 | Ver **detalle** de todo el fondo: cada subcuenta, cupo, posición, sugerencia, decisión y orden | ❌ | 👁 | 👁 |
| PM-35 | Ver las **oportunidades** evaluadas por la IA con su explicación (candidatas, puntaje, confianza, contexto) | Bolsillo Usuarios | 👁 todos | 👁 todos |
| PM-32 | Ver desempeño de la IA (ciclos, costos, calibración de JEV, tasa de acierto, descartes) | ❌ | 👁 | 👁 |
| PM-33 | Exportar reportes | *propio* | fondo | fondo |
| PM-34 | Ver salud de integraciones y resultados de conciliación | ❌ | 👁 | ✅ |

### Dinero (solo administrador)

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-40 | Registrar / anular aportes | ❌ | ❌ | ✅ |
| PM-41 | Registrar retiros | ❌ | ❌ | ✅ |
| PM-42 | Asignar y reducir cupos | ❌ | ❌ | ✅ |
| PM-43 | **Aprobar / rechazar rebalanceos** | ❌ | ❌ | ✅ |
| PM-44 | Solicitar la liquidación del cupo de un empleado | ❌ | ❌ | ✅ |
| PM-45 | Registrar ajustes contables (justificación obligatoria) | ❌ | ❌ | ✅ |

### Cuentas y configuración (solo administrador, salvo el freno)

| ID | Acción | Usuario | Analista | Admin |
|---|---|---|---|---|
| PM-50 | Invitar (correo, rol, cupo inicial) y revocar invitaciones | ❌ | ❌ | ✅ |
| PM-51 | Cambiar el rol de una cuenta | ❌ | ❌ | ✅ |
| PM-52 | Suspender / reactivar cuentas | ❌ | ❌ | ✅ |
| PM-53 | Dar de baja una cuenta y reincorporarla | ❌ | ❌ | ✅ |
| PM-54 | Cambiar parámetros | ❌ | ❌ | ✅ |
| PM-55 | Editar la lista blanca | ❌ | ❌ | ✅ |
| PM-56 | **Freno de emergencia**: apagar `ia_activa` o `trading_activo` | ❌ | ✅ | ✅ |
| PM-57 | **Reanudar**: volver a encender `ia_activa` o `trading_activo` | ❌ | ❌ | ✅ |
| PM-58 | Lanzar un ciclo de IA o una conciliación a mano | ❌ | ❌ | ✅ |
| PM-59 | Gestionar versiones del prompt de contexto (DeepSeek) y de la configuración de decisión de JEV (preguntas, pesos, umbrales; crear, poner en sombra, activar) | ❌ | 👁 | ✅ |
| PM-60 | Ver la bitácora de auditoría | ❌ | ❌ | ✅ |

> **Por qué el analista puede frenar pero no reanudar.** Detener es seguro y
> urgente: quien vea algo raro debe poder pararlo sin esperar a nadie.
> Reanudar implica aceptar el riesgo de nuevo y le corresponde a quien
> gobierna el fondo.

---

## 3. Qué ve cada rol (pantallas)

| Pantalla | Usuario | Analista | Admin |
|---|---|---|---|
| Inicio / Mercado | ✅ | ✅ | ✅ |
| **Oportunidades** (qué está evaluando la IA y por qué) | Usuarios | todas | todas |
| **Mis sugerencias** (bandeja con cuenta regresiva) | ✅ | — | — |
| **Mi cupo** (posiciones, resultado, historial) | ✅ | — | — |
| Nueva orden manual | ✅ | — | — |
| **Bandeja de riesgo** (Arriesgadas + liquidaciones + segundas aprobaciones) | — | ✅ | 👁 |
| **Fondo** (bolsillos, subcuentas, cupos, posiciones) | resumen | detalle | detalle |
| Desempeño de la IA | — | ✅ | ✅ |
| Alertas | ✅ | ✅ | ✅ |
| Reportes | propio | fondo | fondo |
| Perfil y notificaciones | ✅ | ✅ | ✅ |
| **Administración** → Usuarios e invitaciones, Capital (aportes / retiros), Cupos, Rebalanceos, Parámetros, Lista blanca, Interruptores, Salud e integraciones, Bitácora, Prompts | — | — | ✅ |
| Freno de emergencia (botón visible en la barra) | — | ✅ | ✅ |

La navegación se arma según el rol que viene en el token (§4.1). Si alguien
llega por un enlace a una pantalla que su rol no tiene, el enrutador lo
devuelve al inicio.

---

## 4. Cómo se hacen cumplir los permisos

Cuatro capas. **Solo las capas 2, 3 y 4 son seguridad**; la 1 es
experiencia de uso.

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │ 1. APP (Flutter)       Oculta menús y botones según el rol del token   │  UX
 ├─────────────────────────────────────────────────────────────────────────┤
 │ 2. RLS (Postgres)      Cada SELECT filtra filas según rol y dueño      │  seguridad
 │ 3. RPC (Postgres)      Toda escritura pasa por funciones que validan    │  seguridad
 │                        rol, dueño, estado y reglas de riesgo           │
 │ 4. Edge Functions      Verifican el JWT y el rol antes de llamar a     │  seguridad
 │    y Realtime          servicios externos; Realtime filtra canales     │
 │                        con políticas sobre realtime.messages           │
 └─────────────────────────────────────────────────────────────────────────┘
```

### 4.1 El rol viaja en el token (para la app)

Un **Custom Access Token Hook** de Supabase agrega al JWT dos claims leídos de
la tabla `perfiles`:

```json
{ "app_rol": "analista", "app_estado": "activo" }
```

La app los usa para decidir qué mostrar. **La base de datos no confía en
ellos para autorizar**: un cambio de rol tardaría hasta que el token se
renueve (hasta 15 minutos). Para autorizar se consulta la tabla (§4.2).

### 4.2 La fuente de verdad es la tabla `perfiles`

Funciones auxiliares en un esquema privado (no expuesto por la API):

```sql
create schema if not exists private;

-- Rol de quien llama, SOLO si su cuenta está activa. Si está suspendida,
-- de baja o no existe, devuelve NULL y todas las políticas niegan.
create or replace function private.rol_actual()
returns public.rol_app
language sql stable security definer set search_path = ''
as $$
  select p.rol
  from public.perfiles p
  where p.id = (select auth.uid())
    and p.estado = 'activo'
$$;

create or replace function private.es_supervisor()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(private.rol_actual() in ('analista', 'administrador'), false)
$$;
```

> Consecuencia importante: **suspender a alguien corta su acceso a los datos
> al instante**, aunque su token siga vigente, porque cada consulta vuelve a
> mirar `perfiles.estado`.

### 4.3 Lecturas: RLS en todas las tablas

Todas las tablas del esquema `public` tienen RLS activado. Patrón típico:

```sql
alter table public.sugerencias enable row level security;

create policy sugerencias_lectura on public.sugerencias
for select to authenticated
using (
  (select private.es_supervisor())
  or destinatario_id = (select auth.uid())
);
```

Matriz de lectura por tabla (quién ve qué filas):

| Tabla / vista | Usuario | Analista | Admin |
|---|---|---|---|
| `perfiles` | la suya | todas | todas |
| `invitaciones` | — | — | todas |
| `subcuentas` | su cupo | todas | todas |
| `movimientos`, `asientos` | los que tocan su cupo | todos | todos |
| `posiciones`, `protecciones` | las de su cupo | todas | todas |
| `sugerencias`, `decisiones` | las suyas | todas | todas |
| `ordenes`, `ordenes_eventos` | las de su cupo | todas | todas |
| `opiniones_ia` | las suyas | todas | todas |
| `vista_resumen_fondo` (agregado por bolsillo) | ✅ | ✅ | ✅ |
| `patrimonio_diario` | su cupo + agregados | todo | todo |
| `cotizaciones`, `barras_*`, `calendario_mercado`, `lista_blanca`, `parametros` | ✅ | ✅ | ✅ |
| `alertas` | audiencia `todos` o dirigidas a él | + audiencia `analistas` | todas |
| `notificaciones`, `dispositivos` | las suyas | las suyas | las suyas |
| `ciclos_agente`, `senales`, `propuestas_descartadas`, `evaluaciones_ia`, `evaluaciones_candidatos`, `contextos_ia`, `noticias`, `prompts_agente`, `configuraciones_decision` | — (ve lo suyo vía `oportunidades()`) | ✅ | ✅ |
| `movimientos_capital` | — | ✅ | ✅ |
| `salud_integraciones`, `conciliaciones` | — | ✅ | ✅ |
| `auditoria`, `parametros_historial` | — | — | ✅ |

### 4.4 Escrituras: solo por funciones (RPC)

- **Ningún rol tiene permisos de `INSERT`, `UPDATE` o `DELETE` directos**
  sobre tablas de dinero, operaciones, cuentas o configuración. No existen
  políticas de escritura para `authenticated` en esas tablas.
- Toda escritura pasa por una función `security definer` que valida, en este
  orden: **(1)** sesión activa y rol, **(2)** propiedad del recurso,
  **(3)** estado de la entidad, **(4)** motor de políticas
  (`validar_operacion`), **(5)** escribe, audita y publica el evento en
  tiempo real, todo en **una sola transacción**.

Ejemplo, esqueleto de la aprobación:

```sql
create or replace function public.aprobar_sugerencia(p_id uuid)
returns public.sugerencias
language plpgsql security definer set search_path = ''
as $$
declare
  v_rol public.rol_app := private.rol_actual();
  v_s   public.sugerencias;
begin
  if v_rol is null then raise exception 'SESION_INVALIDA'; end if;

  select * into v_s from public.sugerencias where id = p_id for update;  -- bloquea la fila
  if not found then raise exception 'NO_EXISTE'; end if;

  -- Quién decide lo fija la sugerencia al nacer (decide_rol):
  --   'usuario'       → sugerencias sobre un cupo; solo su dueño
  --   'analista'      → Arriesgadas y liquidaciones de cupos
  --   'administrador' → rebalanceos
  if v_s.decide_rol <> v_rol then
    raise exception 'NO_AUTORIZADO';
  end if;
  if v_s.decide_rol = 'usuario' and v_s.destinatario_id <> (select auth.uid()) then
    raise exception 'NO_AUTORIZADO';
  end if;

  -- Estado, vencimiento, banda de precio, reglas de riesgo, doble aprobación...
  -- (ver 08 · Estados y flujos, §1)
  ...
end;
$$;

revoke all on function public.aprobar_sugerencia(uuid) from public, anon;
grant execute on function public.aprobar_sugerencia(uuid) to authenticated;
```

Los errores se devuelven con **códigos estables** (`NO_AUTORIZADO`,
`VENCIDA`, `FUERA_DE_BANDA`, `REGLA_RR_05`, …) que la app traduce a mensajes
en español. Catálogo en [06 §9](06-modelo-de-datos.md#9-códigos-de-error).

### 4.5 Edge Functions

- Las funciones que llama la app (p. ej. `opinion-ia`, `admin-usuarios`)
  verifican el JWT del usuario y luego consultan `private.rol_actual()` con
  su identidad antes de hacer nada.
- Las funciones que llaman los procesos programados (ingesta, agente,
  ejecutor) no aceptan tokens de usuarios: exigen un secreto interno. Ver
  [05 §6](05-arquitectura.md#6-catálogo-de-edge-functions).
- Solo las Edge Functions tienen la llave secreta de Supabase (la que se
  salta RLS), y solo la usan para lo que un usuario no puede hacer (p. ej.
  bloquear una cuenta en Auth).

### 4.6 Tiempo real

Los canales de Supabase Realtime son **privados** y se autorizan con
políticas sobre `realtime.messages` (detalle en
[09 §3](09-tiempo-real-y-notificaciones.md#3-canales-y-quién-los-escucha)). Un
Usuario no puede suscribirse al canal de otro Usuario ni al de riesgo.

---

## 5. Reglas estructurales sobre las cuentas

| ID | Regla |
|---|---|
| **RN-50** | Siempre debe existir **al menos un Administrador activo**. No se puede suspender, dar de baja ni cambiar de rol al último. |
| **RN-51** | Nadie puede suspenderse, darse de baja ni cambiarse el rol a sí mismo. |
| **RN-52** | Las dos aprobaciones de una sugerencia con doble aprobación deben ser de **analistas distintos**. |
| **RN-53** | Una sola decisión por persona por sugerencia. Repetir la misma decisión es idempotente (no falla ni duplica). |
| **RN-54** | Pasar a una persona **de Usuario a otro rol** exige que su cupo no tenga posiciones ni órdenes vivas; el efectivo vuelve a `usuarios_comun` y el cupo se cierra. |
| **RN-55** | Pasar a una persona **a Usuario** le crea un cupo en 0. |
| **RN-56** | Si cambia el rol de un analista que ya dio la **primera aprobación** de una sugerencia pendiente de segunda, esa aprobación **se anula** y la sugerencia vuelve a `pendiente`. |
| **RN-57** | Al suspender o dar de baja, además de cambiar el estado en `perfiles`, se **bloquea la cuenta en Supabase Auth** (no puede renovar su sesión) y se eliminan sus dispositivos de push. |
| **RN-58** | El correo de una cuenta no se edita: es su identidad de Google. |

---

## 6. Ciclo de vida de una cuenta

```
 invitación ──(primer login con Google)──► ACTIVO ◄──(reactivar)── SUSPENDIDO
     │                                       │  └──────(suspender)──────►┘
     │ (revocar / vencer)                    │
     ▼                                       └──(dar de baja; exige cupo vacío)──► BAJA
  sin cuenta                                                                     │
                            ACTIVO ◄──(reincorporar: cupo nuevo en 0)────────────┘
```

Estados, transiciones y efectos en detalle en
[08 · Estados y flujos](08-estados-y-flujos.md#5-cuenta-e-invitación). Cómo
funciona la invitación con Google en
[04 · Autenticación](04-autenticacion-oauth.md).
