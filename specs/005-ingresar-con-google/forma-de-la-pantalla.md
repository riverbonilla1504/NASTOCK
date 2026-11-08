# Forma de la pantalla de ingreso (`/impeccable shape`)

HU-005 · T010. Brief de diseño, sin código. Modo: **Operate** (la puerta de una app de trabajo: precisión y sobriedad, no expresión). El mundo visual ya está elegido y no se discute: `DESIGN.md` (Almanaque). Hecho de forma autónoma, sin entrevista, porque la historia, `DESIGN.md` y el encargo cierran las preguntas; lo supuesto está marcado como **Supuesto**.

## 1. Quién llega y qué necesita

Una persona del equipo, ya invitada, con su Gmail, casi siempre en el teléfono (el Administrador, a veces en la web de escritorio). Quiere entrar en un toque. Si algo falla, necesita saber **qué pasó y qué hacer** (voz de `PRODUCT.md`: tuteo, frases cortas). Éxito: toca un botón, elige cuenta en Google y cae en la pantalla de inicio. No hay nada más que hacer aquí: ni registro, ni contraseña, ni recuperación.

## 2. Idea de estructura

El Almanaque en su forma más corta: la **barra grafito** arriba con el nombre, y una **hoja blanca sobre papel** con lo único que se puede hacer. Sin ilustración, sin logotipo (no existe uno; HU-116 no lo creó), sin círculo con ícono sobre el título, sin divisor "o" ni botones de redes. La firma de la jornada (franja) no va: necesita el calendario del mercado, que sin sesión no se puede leer.

Una columna, alineada arriba (no centrada en vertical: centrar es el gesto de plantilla de login). En ventanas anchas la hoja mide como máximo **420 dp**, centrada en horizontal bajo la barra, con 32 dp de aire arriba.

## 3. Jerarquía, de arriba abajo

| Bloque | Componente | Contenido |
|---|---|---|
| Barra | `BarraSuperior` (título solo, sin `inferior`) | "RiTech Inversiones" |
| Hoja | `Tarjeta` (16 dp de relleno, sombra de tarjeta) sobre `papel` | lo de abajo |
| Título | Headline pequeño condensado (24 px) | "Entra con tu cuenta de Google" |
| Ayuda | Body, `tinta-suave` | "Solo pueden entrar las personas que invitó el administrador. Usa la cuenta de Google con la que te invitaron." |
| Aviso (solo si hay fallo o falta configuración) | `AvisoEnLinea` | ver §4 |
| Acción | `BotonPrimario` de ancho completo, 48 dp | "Entrar con Google" |
| Solo pruebas (solo con `MODO_PRUEBAS`) | rótulo + `Campo` ×2 + `BotonSecundario` | ver §5 |
| Pie (fuera de la hoja) | Body pequeño, `tinta-tenue` | "MVP en paper trading: una persona siempre aprueba." |

El aviso va **entre la ayuda y el botón**: se lee primero el mensaje y justo debajo está el botón para reintentar. El botón es la única acción primaria de la pantalla.

## 4. Estados y textos

| Estado | Qué se ve |
|---|---|
| Inactivo | Título, ayuda y botón "Entrar con Google". |
| Ingresando | El botón se deshabilita y dice "Procesando…" con su indicador de 16 dp (`BotonPrimario(enviando: true)`, `docs/08` §9.3). Nada más cambia. En web la página se va a Google y el estado desaparece con ella. |
| Cancelado (cerró la ventana de Google) | Vuelve a **inactivo, sin mensaje** (CA-4). |
| Fallo | `AvisoEnLinea` de tipo **error** (borde doble, cuadrado lleno de tinta con equis, región viva, **sin rojo**) con el mensaje. El botón queda activo para reintentar. Un nuevo intento borra el aviso. |
| Falta configurar (desarrollo) | `AvisoEnLinea` de tipo **advertencia** (rombo, borde discontinuo) y el botón deshabilitado. No sale en producción: el despliegue pasa las variables. |

Mensajes de fallo (ya definidos en `docs/04` §11 y en la decisión del 2026-11-08; no se inventan otros):

- "Tu correo no tiene una invitación vigente. Pídele una al administrador."
- Rechazos del hook por dominio o proveedor: el texto que llega del servidor.
- "Tu cuenta está suspendida. Comunícate con el administrador."
- "No hay conexión. Revisa tu internet e inténtalo de nuevo."
- "No pudimos iniciar tu sesión. Inténtalo de nuevo."

**Textos que no están en `docs/` (decisión de tono, a revisar por Javier):** el título, la ayuda, el botón, el pie y los de "solo pruebas". Ninguno habla de "corporativa" ni "de RiTech". Los avisos de configuración son para quien desarrolla: "Falta configurar la conexión: ejecuta la app con --dart-define=SUPABASE_URL=… y --dart-define=SUPABASE_PUBLISHABLE_KEY=…" (es el de `PaginaInicio`) y "Falta configurar el ingreso con Google: ejecuta la app con --dart-define=GOOGLE_WEB_CLIENT_ID=…".

## 5. Ingreso con correo (solo `MODO_PRUEBAS`)

Debajo del botón de Google, separado por una regla de 1 px (`regla`) y un rótulo en label medium, mayúsculas: **"SOLO PRUEBAS"**, para que nadie lo confunda con una función. Dentro: `Campo` "Correo" (teclado de correo), `Campo` "Contraseña" con el parámetro nuevo `oculto`, y `BotonSecundario` "Entrar con correo" (contorno de tinta, jerarquía menor que el botón de Google). Los dos campos con la misma regla de error que el resto del sistema; el mensaje de un fallo sale en el mismo aviso de arriba, no en cada campo. Con `MODO_PRUEBAS` apagado, este bloque **no existe** en el árbol (no solo oculto).

## 6. Layout, texto grande y teclado

- Margen lateral de 16 dp; módulo de 4 dp; objetivos de 48 dp.
- Todo el cuerpo va en un `SingleChildScrollView` con el borde inferior respetando el área segura y el teclado: con el formulario de pruebas y el teclado abierto, el campo enfocado queda visible.
- **Texto al 200 %**: nada tiene alto fijo salvo el mínimo de 48 dp de los controles; el título y la ayuda ocupan las líneas que necesiten; el botón puede crecer a dos líneas. Sin recortes con puntos suspensivos en el título ni en los mensajes.
- Orden de foco y de lectura: título (encabezado), ayuda, aviso, botón, y luego el bloque de pruebas.
- Claro y oscuro con los mismos roles; el contraste de los pares ya medidos no cambia (no hay colores nuevos).

## 7. Color, forma y movimiento

- Gris sobre gris. **Ningún morado** en esta pantalla salvo el foco de los campos (que ya es del sistema); el morado es de los datos vigentes y aquí no hay datos.
- El error se reconoce por la forma, no por el color (`DESIGN.md`, "La regla del error sin rojo").
- Sin movimiento propio: solo el cambio de estado del botón (150 ms, del sistema). El aviso aparece sin animación.

## 8. Lo que no se hace (antiobjetivos)

Ilustración o logotipo inventado; tarjeta de cristal; degradado morado; texto "Bienvenido de nuevo 👋"; ícono grande sobre el título; botón blanco con la "G" de colores de Google (sin el recurso oficial ni licencia clara en el repositorio; la pantalla de consentimiento está en modo prueba); mostrar el detalle de una excepción; texto en rojo.

## 9. Decisiones abiertas (no las inventa quien construye)

1. **Marca "G" de Google en el botón.** Hoy va sin ella. Si Google la exigiera para publicar la app (hoy no: consentimiento Externo en modo prueba), se agrega como recurso al sistema con su entrada en `DESIGN.md`.
2. **`PRODUCT.md` está desactualizado** ("cuenta de Google Workspace de RiTech", "Empresa cerrada… con cuenta de Google Workspace"). La decisión del 2026-11-08 lo contradice. No lo toqué (una tarea de diseño no repara el contexto de paso); conviene refrescarlo con `/impeccable doctor` o a mano al cerrar HU-004.
3. **Dónde va el aviso de configuración de `PaginaInicio`.** Si la app abre sin sesión, el aviso que hoy vive en `PaginaInicio` se ve en el ingreso; `PaginaInicio` lo conserva para quien llegue con sesión.

## 10. Verificación esperada (T014)

Revisar en Chrome a 360 dp y a 1280 dp, claro y oscuro, a escala de texto 1,0 y 2,0, con y sin `MODO_PRUEBAS`, y cada uno de los seis fallos; auditar contraste, foco de teclado y lectura con lector de pantalla; en el emulador de Android solo si la memoria de la PC lo permite.
