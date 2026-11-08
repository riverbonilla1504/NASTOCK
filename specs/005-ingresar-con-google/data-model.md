# Modelo de datos: HU-005 · Ingresar con Google en Android y web

**Sin tablas, columnas ni migraciones nuevas.** La historia usa `perfiles` e `invitaciones` ya existentes (HU-001, HU-002) a través de Supabase Auth; no lee ni escribe ninguna directamente.

## Estados y tipos de la app (no persistentes)

### `ResultadoDeIngreso`

| Valor | Cuándo |
|---|---|
| `exito` | La sesión quedó iniciada (nativo: `signInWithIdToken` respondió; correo: `signInWithPassword` respondió). En web no se devuelve: la página se va a Google y la sesión llega al volver, por `onAuthStateChange`. |
| `cancelado` | La persona cerró la ventana de Google. Sin mensaje (CA-4). |

### `TipoDeFalloDeIngreso` y su texto (`docs/04` §11, ajustado por la decisión del 2026-11-08)

| Tipo | Texto en pantalla |
|---|---|
| `sinInvitacion` | "Tu correo no tiene una invitación vigente. Pídele una al administrador." |
| `dominioNoPermitido` | "Solo se admiten cuentas de Google invitadas." |
| `proveedorNoPermitido` | "Solo puedes ingresar con tu cuenta de Google." |
| `cuentaSuspendida` | "Tu cuenta está suspendida. Comunícate con el administrador." |
| `sinConexion` | "No hay conexión. Revisa tu internet e inténtalo de nuevo." |
| `inesperado` | "No pudimos iniciar tu sesión. Inténtalo de nuevo." |

"Cuenta fuera de la lista de usuarios de prueba" no tiene tipo: lo muestra Google y no llega a la app.

### `EstadoDeIngreso` (controlador de la pantalla)

```
inactivo ──toca "Entrar con Google"──▶ ingresando ──éxito──▶ (el enrutador lleva a /inicio)
    ▲                                       │
    │                                       ├──cancelado──▶ inactivo   (sin mensaje)
    └────────── vuelve a tocar ◀── fallo(tipo) ◀── error
```

### Estados del componente de confirmación (`docs/08` §9.3)

```
inactivo → confirmando → enviando → hecho
                │            └── error (código → mensaje) → confirmando (reintento)
                └── cancelado
```

## Sesión

`sesionProvider`: `Session?` de `supabase_flutter` (null sin sesión). Los claims `app_rol` y `app_estado` los lee `perfilProvider` (HU-001), no esta historia.
