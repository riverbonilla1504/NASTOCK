# Plan de implementación: HU-084 · Gestor de tiempo real en la app

**Rama**: `084-gestor-de-tiempo-real` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

Es una historia **de la app**: sin migraciones, tablas ni Edge Functions (HU-083 ya dejó los canales privados, la política `canales_permitidos` y los eventos en la base). Se agrega `lib/core/realtime/` (M-13): (1) los canales por rol y el evento de tiempo real; (2) la fuente de tiempo real sobre `supabase_flutter` detrás de una interfaz; (3) el gestor, que abre los canales al iniciar sesión, deduce el estado de la conexión y avisa cuándo pedir las fotos otra vez; (4) los providers `gestorDeTiempoRealProvider`, `conexionProvider`, `decisionesHabilitadasProvider` y `relojProvider`; (5) el patrón foto y eventos reutilizable (`FotoYEventosNotifier`); (6) la barra de conexión y su integración en el cascarón de navegación; (7) pruebas y E2E (CA-1).

## Contexto técnico

**Lenguaje/Versión**: Dart 3.13 / Flutter 3.47. **Dependencias nuevas**: ninguna (`supabase_flutter` y `flutter_riverpod` ya están).

**Lo que ya existe**: `clienteSupabaseProvider`, `sesionProvider`, `accesoDeSesionProvider` (rol y estado del token), `RolApp`, `CascaronDeNavegacion`, `AvisoEnLinea`, tokens de `lib/app/tema.dart`; en la base, `private.publicar_evento` / `private.carga_evento` (HU-083), `estado_mercado().ahora` (hora del servidor, `docs/06` §6).

**Pruebas**: `flutter test` (unitarias y de widget con una fuente y un reloj en memoria) y el E2E de la app en Chrome (`integration_test/app_test.dart`).

**Plataforma**: Android y web. **Restricciones**: el cliente solo escucha, nunca publica (`docs/09` §3); los eventos llevan identificadores y versión, nunca montos (`docs/09` §4); el token se renueva sin volver a suscribirse (`docs/09` §7); sin llaves; solo tokens y componentes existentes (D-67).

## Revisión de la constitución

Cumple `CLAUDE.md`:

- La autorización sigue en la base (RLS y la política de `realtime.messages`); la lista de canales por rol solo evita pedir lo que la base negaría.
- Los eventos no traen montos: el dato se lee siempre por la API (donde aplica RLS).
- Sin llaves, sin servicios nuevos, sin cambios en reglas de `docs/`.

Reevaluada tras el diseño: sin violaciones.

## Alcance frente a otras historias

| Pieza | Dueño | Aquí |
|---|---|---|
| Gestor, canales por rol, estados de conexión, reloj corregido, patrón foto y eventos, barra "Reconectando…" | HU-084 | Sí |
| Canales privados, política y eventos en la base | HU-083 | Ya en `main` |
| Pantalla de mercado en vivo (consume `mercado` y el reloj) | HU-030 | No |
| Escuchar el canal propio para cerrar la sesión | HU-010 | No (usa `gestor.eventos`) |
| `perfil_actualizado` | HU-011 | No (usa `gestor.eventos`) |
| Deshabilitar los botones de cada pantalla | cada pantalla | Aquí solo `decisionesHabilitadasProvider` |

## Decisiones de diseño

- **D-1 · Fuente detrás de una interfaz.** `FuenteDeTiempoReal` (eventos, señales, abrir canal, cerrar) aísla `supabase_flutter`; las pruebas usan una fuente en memoria.
- **D-2 · Canales por rol** (`docs/09` §3): todos `mercado`, `fondo`, `usuario:{id}`; Analista, además, `supervision`; Administrador, además, `supervision` y `admin`. Siempre privados.
- **D-3 · Un gestor por sesión.** `gestorDeTiempoRealProvider` depende de `SuscripcionesDeRol` (id y rol, por valor), así renovar el token no cierra ni abre canales; cambiar de rol o cerrar sesión sí. Sin sesión o con cuenta no activa: `null`. `ActivadorDeTiempoReal` (en `MaterialApp.builder`) lo mantiene vivo y avisa al volver a primer plano.
- **D-4 · Estado de la conexión.** `ControlDeConexion` lo deduce de señales (socket y canales): `conectado` mientras todos los canales siguen suscritos; al perder socket o canal, `reconectando`; al volver a tenerlos todos, `conectado` y aviso de reconexión (se piden las fotos otra vez, CB-66). **`sinConexion` no tiene regla en `docs/`**: se implementa como "un intento de reconectar falló después de perder la conexión" y queda como pregunta abierta para el responsable del producto; no se edita `docs/` por ello.
- **D-5 · Foto y eventos** (`docs/08` §9.2). `FotoYEventosNotifier<T>` pide la foto al montar, ignora eventos con versión ≤ la que tiene, pide el registro por la API si es mayor, quita el que la API ya no entrega, nunca reemplaza con una respuesta más vieja y pide la foto completa al reconectar.
- **D-6 · Reloj corregido** (`docs/08` §9.1, CB-70). El desfase se mide contra `estado_mercado().ahora` (descontando la mitad del viaje) al iniciar sesión y al reconectar; si no se puede medir se conserva el anterior. Las cuentas regresivas usan `RelojCorregido.ahora()`.
- **D-7 · Barra de conexión** (FR-189). `ContenidoConConexion` en el cascarón: barra `AvisoEnLinea` "Reconectando…" (informativa, datos al 50 %) o "Sin conexión" (advertencia). El árbol mantiene la misma forma para no perder el estado del contenido.

## Estructura del código

### Documentación de esta funcionalidad

```text
specs/084-gestor-de-tiempo-real/
├── spec.md
├── plan.md
├── tasks.md                    # /speckit-tasks
└── checklists/requirements.md
```

### Código

```text
lib/core/realtime/
├── canales.dart                     # Canales, canalesDeRol
├── evento_de_tiempo_real.dart       # EventoDeTiempoReal, EntidadDeEvento
├── estado_conexion.dart             # EstadoConexion, SenalDeConexion, ControlDeConexion
├── fuente_de_tiempo_real.dart       # FuenteDeTiempoReal, FuenteSupabaseDeTiempoReal
├── gestor_de_tiempo_real.dart       # GestorDeTiempoReal
├── tiempo_real_provider.dart        # gestor, conexión, decisionesHabilitadas
├── reloj.dart                       # RelojCorregido, relojProvider
├── foto_y_eventos.dart              # FotoYEventosNotifier<T>
└── activador_de_tiempo_real.dart    # ciclo de vida
lib/shared/widgets/barra_de_conexion.dart
lib/app/aplicacion.dart              # + ActivadorDeTiempoReal
lib/app/cascaron_de_navegacion.dart  # + ContenidoConConexion

test/core/realtime/                  # canales, estado, gestor, reloj, foto y eventos, provider
test/shared/widgets/barra_de_conexion_test.dart
test/app/cascaron_de_navegacion_test.dart, aplicacion_test.dart, enrutador_test.dart
integration_test/app_test.dart       # CA-1: canales por rol y conexión tras ingresar
```

**Decisión de estructura**: la de `docs/05` §9.1 y `docs/17` M-13 (`lib/core/realtime/`).

## Seguimiento de complejidad

Sin violaciones que justificar.
