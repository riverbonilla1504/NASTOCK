# Modelo de datos: HU-006 · Navegación y guardas según el rol

**Sin tablas, columnas ni migraciones nuevas.** La historia lee `app_rol` y `app_estado` del token; no consulta ni escribe `perfiles`.

## Tipos de la app (no persistentes)

### Destino (registro de `lib/app/destinos.dart`)

| Campo | Significado |
|---|---|
| `ruta` | Ruta base, p. ej. `/cupo`. Las subrutas (`/admin/usuarios`) pertenecen al mismo destino |
| `etiqueta` | Texto del menú, p. ej. "Mi cupo" |
| `icono` | Ícono del menú |
| `roles` | Roles que lo ven en el menú y pueden abrir su ruta |
| `pantalla` | Constructor de la pantalla; hoy un marcador salvo Mercado (`PaginaInicio`) |

### Destinos del MVP corto (`docs/03` §3)

| Destino | Ruta | Usuario | Analista | Administrador | Pantalla de |
|---|---|:-:|:-:|:-:|---|
| Mercado | `/inicio` | ✅ | ✅ | ✅ | HU-030 (hoy `PaginaInicio`) |
| Oportunidades | `/oportunidades` | ✅ | ✅ | ✅ | HU-048 (marcador) |
| Mi cupo | `/cupo` | ✅ | — | — | HU-019 (marcador) |
| Alertas | `/alertas` | ✅ | ✅ | ✅ | HU-085 (marcador) |
| Administración | `/admin` | — | — | ✅ | HU-097 y HU-003 (marcador) |

### `AccesoDeRuta`

| Valor | Significa |
|---|---|
| `permitido` | Entra normalmente |
| `soloLectura` | Entra y la pantalla deshabilita sus acciones (Administrador en `/riesgo/*`) |
| `denegado` | El enrutador lo lleva a `/inicio` |

### Política (`accesoDeRuta(rol, ruta)`)

| Ruta | Usuario | Analista | Administrador | Rol desconocido |
|---|:-:|:-:|:-:|:-:|
| `/inicio` | permitido | permitido | permitido | permitido |
| `/oportunidades`, `/alertas` | permitido | permitido | permitido | denegado |
| `/cupo` | permitido | denegado | denegado | denegado |
| `/admin`, `/admin/*` | denegado | denegado | permitido | denegado |
| `/riesgo`, `/riesgo/*` | denegado | permitido | **soloLectura** | denegado |
| cualquier otra | según su destino; sin destino, denegado | | | |

### Decisión de la guarda (`redirigirSegunAcceso`)

```
catálogo (/catalogo…)                          → se queda
sin sesión                                     → /ingreso            (si no está ya en él)
con sesión, app_estado ≠ activo (o sin claim)  → /cuenta-suspendida  (si no está ya en ella)
con sesión activa, /ingreso o /cuenta-suspendida → /inicio
con sesión activa, acceso denegado             → /inicio
en otro caso                                   → se queda
```

Sin ciclos: `/inicio` es `permitido` para cualquier rol, también uno desconocido.

## Sesión

`accesoDeSesionProvider`: `AccesoDeSesion { haySesion, rol, estado }` derivado de `sesionProvider` y de los claims de su token (HU-005, HU-001). Cambia al ingresar, al cerrar sesión y al renovarse el token.
