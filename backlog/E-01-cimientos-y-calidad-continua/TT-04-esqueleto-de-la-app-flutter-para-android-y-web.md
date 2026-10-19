# TT-04 · Esqueleto de la app Flutter para Android y web

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20, M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `M-01` · `prioridad-alta` |

## Qué hay que hacer y por qué

Crear el proyecto Flutter `com.ritech.inversiones` para Android y web con la estructura por funcionalidades, Riverpod, go_router, el cliente de Supabase y la traducción de códigos de error. Es el armazón donde cada historia agrega su pantalla.

## Documentación fuente

05 §3.1 · 05 §9 · 05 §10.1 · 06 §9 · D-16 · D-18 · D-46

## Requisitos funcionales

- [FR-002 · Mensajes de error en español por código](../requisitos-funcionales/FR-002-mensajes-de-error-en-espanol-por-codigo.md)
- [FR-003 · Formato de dinero y de horas](../requisitos-funcionales/FR-003-formato-de-dinero-y-de-horas.md)

## Criterio de terminado

- [ ] La app compila y abre en Android y en web con una pantalla inicial y la estructura `lib/app`, `lib/core`, `lib/features` y `lib/shared`.
- [ ] Cada código del catálogo de 06 §9 tiene su mensaje en español y un código desconocido muestra un mensaje genérico, nunca el texto crudo (prueba unitaria).
- [ ] Los montos se muestran en USD con dos decimales y las horas en hora de Bogotá (prueba unitaria).
- [ ] `dart format`, `flutter analyze` y `flutter test` pasan.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] `flutter create` para Android y web con el identificador `com.ritech.inversiones`.
- [ ] Paquetes base de 05 §3.1: `supabase_flutter`, `flutter_riverpod`, `go_router`, `freezed` / `json_serializable` e `integration_test`; los demás los agrega la historia que los usa.
- [ ] `lib/app/`: arranque, enrutador con la ruta de inicio y tema base.
- [ ] `lib/core/`: cliente de Supabase configurado con `--dart-define` (URL y llave publicable), errores y códigos, formato de dinero y de fechas.
- [ ] Pruebas unitarias de la traducción de errores y del formato.
- [ ] Comprobar la regla de arquitectura de `scripts/verificar.sh`: la app no menciona la llave secreta ni llaves de proveedores.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-01 · Repositorio, GitHub Projects y wiki](TT-01-repositorio-github-projects-y-wiki.md) | El código de la app vive en el repositorio y lo valida CI. |
| Habilita | [TT-06 · Arnés E2E de backend y de la app](TT-06-arnes-e2e-de-backend-y-de-la-app.md) | TT-06: el E2E de la app necesita la app. |
| Habilita | [HU-005 · Ingresar con Google en Android y web](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) | HU-005: la pantalla se construye sobre el esqueleto de la app. |
| Habilita | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | HU-084: vive en `lib/core/` de la app. |
| Habilita | [HU-115 · Motor ×2 teórico de la v2 con sus pruebas](../E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md) | HU-115: se copia dentro del esqueleto de la app. |
| Habilita | [HU-116 · Tema, estilos, widgets y fuentes de la v2](../E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md) | HU-116: se copia dentro del esqueleto de la app. |
| Habilita | [HU-117 · Exportador de reportes de la v2 con sus pruebas](../E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md) | HU-117: se copia dentro del esqueleto de la app. |
