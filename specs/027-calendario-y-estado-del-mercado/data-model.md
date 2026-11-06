# Modelo de datos: HU-027 · Calendario, reloj y estado del mercado

## Tabla nueva

### `public.calendario_mercado` (`docs/06` §5.2)

| Columna | Tipo | Notas |
|---|---|---|
| `fecha` | `date` PK | Día de mercado en Nueva York. |
| `apertura` | `timestamptz not null` | En UTC, con el horario de verano ya resuelto. |
| `cierre` | `timestamptz not null` | Restricción `cierre > apertura`. |
| `sesion` | `text not null` | `regular` o `media_jornada`. |

- **Feriados y fines de semana no tienen fila**: el mercado está cerrado todo el día (CB-49).
- **Seguridad** (`docs/03` §4.3, `docs/06` §7): RLS activo; `authenticated` solo `select`; política de lectura `(select private.rol_actual()) is not null` (toda persona con la cuenta activa); `anon` sin permisos; sin políticas de escritura.

## Tabla que se completa

`public.lista_blanca` (HU-026) ya trae `fraccionable`, `negociable` y `sincronizado_en` (nulos en la semilla). La sincronización diaria los llena y pone `activo = false` si `negociable` pasa a `false`.

## Funciones de `private` (las llaman las Edge Functions con `_shared/bd.ts`, o SQL)

| Función | Devuelve | Qué hace |
|---|---|---|
| `mercado_abierto()` | `boolean` | Existe un día con `apertura <= ahora < cierre`. |
| `mercado_en_ventana(p_margen interval)` | `boolean` | Existe un día con `apertura − p_margen <= ahora < cierre`. |
| `sincronizar_calendario(p_desde date, p_hasta date, p_datos jsonb)` | `table(guardados int, eliminados int)` | Inserta o actualiza los días de `p_datos` (`[{fecha, apertura, cierre, sesion}]`, horas en UTC) y borra los de `[p_desde, p_hasta]` que no vienen. `guardados` cuenta las filas nuevas o cambiadas: repetir la llamada da 0. Rechaza una apertura que no cae en su día de Nueva York (atrapa una conversión de horario de verano mal hecha, CB-51). |
| `sincronizar_activos(p_datos jsonb)` | `table(bolsillo, simbolo, desactivado boolean)` | Guarda `[{simbolo, negociable, fraccionable}]` en todas las filas de `lista_blanca` de ese símbolo; devuelve una fila por fila actualizada y si se desactivó en esta llamada. No reactiva nunca. |
| `margenes_de_compra()` ¹ | `table(tras_apertura int, antes_cierre int)` | 5 y 15 minutos (`docs/02` §10). |
| `ventana_compras_abierta()` ¹ | `boolean` | `apertura + tras_apertura <= ahora < cierre − antes_cierre` (RR-07). |

¹ Se construyen al final, con la decisión sobre `parametros` (plan, punto abierto 1).

Todas con `security definer`, `set search_path = ''`, sin permiso para `public`, `anon` ni `authenticated`.

## RPC `public.estado_mercado()` ¹ (`docs/06` §6)

Solo lectura, `security definer`, para toda persona activa (`private.rol_actual()`; si es nulo, `NO_AUTORIZADO`).

| Columna | Significado |
|---|---|
| `estado` | `cerrado`, `pre_apertura`, `abierto_sin_compras`, `abierto` o `cierre_proximo` (`docs/08` §6). |
| `abierto` | `apertura <= ahora < cierre`. |
| `ahora` | `private.ahora()`: la app corrige su reloj local con esta hora (`docs/09` §1). |
| `proxima_apertura` / `proximo_cierre` | Para la cuenta regresiva (RN-42). |
| `compras_desde` / `compras_hasta` | Ventana de compras del día de mercado vigente o siguiente. |
| `ventana_compras_abierta` | `compras_desde <= ahora < compras_hasta`. |
| `sesion` | `regular` o `media_jornada`; nulo si no hay sesión próxima. |
| `datos_actualizados_en` | Frescura de los datos (punto abierto 3). |

## Transiciones del estado (calculadas, no guardadas)

```text
cerrado ──(apertura − 10 min)──▶ pre_apertura ──(apertura)──▶ abierto_sin_compras
   ▲                                                              │ (apertura + 5 min)
   │                                                              ▼
   └────────────(cierre)──── cierre_proximo ◀──(cierre − 15 min)── abierto
```
