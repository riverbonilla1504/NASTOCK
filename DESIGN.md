---
name: RiTech Inversiones
description: Panel financiero limpio en grises con un único acento morado; cifras en monoespaciada y una gráfica de línea fina como protagonista.
colors:
  tinta: "#18181B"
  tinta-suave: "#52525B"
  tinta-tenue: "#6B6B74"
  papel: "#F7F7F8"
  hoja: "#FFFFFF"
  relleno: "#F1F1F3"
  regla: "#E4E4E7"
  regla-fuerte: "#8E8E97"
  morado: "#6A45E0"
  morado-tenue: "#EFEBFD"
  sobre-morado: "#FFFFFF"
  alza: "#2D6A4F"
  baja: "#A3383C"
  grafito: "#27272A"
  sobre-grafito: "#F4F4F5"
  sobre-grafito-suave: "#B4B4BC"
  velo: "#FFFFFFE6"
  velo-hoja: "#FFFFFFF7"
  velo-grafito: "#27272AE0"
  tinta-oscuro: "#EDEDEF"
  tinta-suave-oscuro: "#A1A1AA"
  tinta-tenue-oscuro: "#8B8B94"
  papel-oscuro: "#0E0E10"
  hoja-oscuro: "#17171A"
  relleno-oscuro: "#222226"
  regla-oscuro: "#2B2B30"
  regla-fuerte-oscuro: "#6F6F78"
  morado-oscuro: "#B3A1FF"
  morado-tenue-oscuro: "#28224A"
  sobre-morado-oscuro: "#18181B"
  alza-oscuro: "#7FC9A0"
  baja-oscuro: "#F0908F"
  grafito-oscuro: "#2E2E33"
  sobre-grafito-suave-oscuro: "#A9A9B2"
  velo-oscuro: "#17171AE0"
  velo-hoja-oscuro: "#17171AF5"
  velo-grafito-oscuro: "#3A3A40EB"
typography:
  cifra-grande:
    fontFamily: "JetBrainsMono, monospace"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: 1.15
    fontFeature: "tnum"
  headline-small:
    fontFamily: "Inter, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.25
  title-medium:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.35
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  body-medium:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
  body-small:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.2
  cifra:
    fontFamily: "JetBrainsMono, monospace"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    fontFeature: "tnum"
  eje:
    fontFamily: "JetBrainsMono, monospace"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
    fontFeature: "tnum"
rounded:
  control: "6px"
  hoja: "8px"
spacing:
  x1: "4px"
  x2: "8px"
  x3: "12px"
  x4: "16px"
  x5: "20px"
  x6: "24px"
  x8: "32px"
  objetivo-tactil: "48px"
components:
  boton-primario:
    backgroundColor: "{colors.morado}"
    textColor: "{colors.sobre-morado}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 20px"
    height: "48px"
  boton-primario-deshabilitado:
    backgroundColor: "{colors.relleno}"
    textColor: "{colors.tinta-tenue}"
    rounded: "{rounded.control}"
    height: "48px"
  boton-secundario:
    backgroundColor: "{colors.relleno}"
    textColor: "{colors.tinta}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 20px"
    height: "48px"
  boton-texto:
    backgroundColor: "transparent"
    textColor: "{colors.morado}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "48px"
  tarjeta:
    backgroundColor: "{colors.hoja}"
    rounded: "{rounded.hoja}"
    padding: "16px"
  campo:
    backgroundColor: "{colors.hoja}"
    textColor: "{colors.tinta}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "14px 12px"
  chip-de-estado:
    backgroundColor: "{colors.hoja}"
    textColor: "{colors.tinta}"
    rounded: "16px"
    padding: "0 12px"
    height: "32px"
  chip-de-estado-destacado:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.morado}"
    rounded: "16px"
    padding: "0 12px"
    height: "32px"
  aviso-en-franja:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.tinta}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
    padding: "12px 12px 12px 14px"
  selector-de-rango-elegido:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.morado}"
    typography: "{typography.cifra}"
    rounded: "16px"
    height: "32px"
  barra-superior:
    backgroundColor: "{colors.hoja}"
    textColor: "{colors.tinta}"
    typography: "{typography.headline-small}"
    height: "56px"
  barra-de-pestanas:
    backgroundColor: "{colors.velo}"
    textColor: "{colors.tinta-suave}"
    height: "56px"
  barra-de-pestanas-actual:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.tinta}"
  aviso-temporal:
    backgroundColor: "{colors.velo-grafito}"
    textColor: "{colors.sobre-grafito}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
  hoja-inferior:
    backgroundColor: "{colors.velo-hoja}"
    rounded: "{rounded.hoja}"
---

# Design System: RiTech Inversiones

## Overview

> **Quién manda.** DESIGN.md manda en lo visual (tokens, color, tipografía, componentes, movimiento y tono visual) por la decisión D-67; `docs/` manda en reglas de negocio, flujos, permisos, datos y textos de error; si chocan en algo no visual, manda `docs/`. La dirección visual vigente es la de **D-69** (estilo Alpaca), que reemplaza al "Almanaque". Toda pantalla nueva usa los tokens de `lib/app/tema.dart` y los componentes de `lib/shared/widgets/`, con `/impeccable shape` antes y `/impeccable audit` + `polish` al final (`docs/15` §12).

**Creative North Star: "El panel limpio"**

Un panel financiero sobrio: mucho espacio en blanco, tarjetas blancas con un borde fino, texto en una sans limpia (Inter) y **todas las cifras en monoespaciada** (JetBrains Mono): montos, cantidades, horas y ejes. La protagonista es la **gráfica de línea fina**: una sola línea de 2 px en el morado, un relleno plano muy suave debajo, cuadrícula horizontal punteada y casi invisible, sin ejes dibujados ni puntos, y el selector de rango **1D · 1M · 1Y · All** a todo el ancho.

Los colores son nuestros: grises neutros y un único acento **morado**. El morado marca lo accionable y lo vigente: botón principal, línea de gráfica, foco de un campo, rango elegido y, en tono tenue, lo seleccionado y los avisos en franja. El verde y el rojo apagados solo dicen hacia dónde se movió un precio, y nunca solos: siempre con flecha y signo. Los estados se leen además por la **forma de la línea**, así que la app funciona igual para quien no distingue colores.

**El celular va primero** (360 a 412 dp): una columna, la gráfica a todo el ancho, objetivos táctiles de 48 dp o más y letra que sigue la configuración del sistema. El riel lateral solo aparece en pantallas anchas.

No se copia ningún archivo de la marca Alpaca (logo, íconos, fuentes, pantallas): se usan Inter y JetBrains Mono (OFL) e íconos de línea de Material. El sistema rechaza el tablero de trading en negro con verde neón, el estilo "panel de IA" con degradados morados y brillos, y la alerta genérica de caja roja con ícono rojo.

**Key Characteristics:**
- Interfaz gris con un acento morado.
- La gráfica de línea fina como pieza central (`GraficaDeLinea` y `TarjetaDeGrafica`).
- Inter para el texto; JetBrains Mono para toda cifra.
- Tarjetas blancas con borde fino de 1 px y esquinas de 8 dp; controles de 6 dp; módulo de 4 dp.
- Sombras casi inexistentes; solo lo que flota lleva sombra y velo con desenfoque.
- Claro y oscuro con los mismos roles; WCAG 2.2 AA medido.

## Colors

Grises fríos casi neutros con un único acento morado; cada token tiene su par en oscuro (sufijo `-oscuro`) con el mismo rol.

### Primary
- **Morado** (`morado`): botón principal, línea de gráfica, foco de campo (2 px), cursor, texto del rango elegido, hoy en el calendario, aguja de "ahora" y texto de acciones de texto. En oscuro se aclara (`morado-oscuro`) para conservar el contraste.
- **Morado tenue** (`morado-tenue`): fondo de lo seleccionado (pestaña actual de la isla, rango elegido, selección de texto), de los avisos en franja y del chip destacado. Nunca un fondo de sección.
- **Sobre morado** (`sobre-morado`): texto del botón principal.

### Secondary
- **Alza verde apagado** (`alza`) y **baja rojo apagado** (`baja`): solo la dirección de una variación de precio, siempre con flecha (↑ ↓, guion sin cambio) y signo. Una variación de 0,00 % va en `tinta-suave`.

### Neutral
- **Tinta** (`tinta`): texto, íconos y marcas. **Tinta suave** (`tinta-suave`): texto secundario y rótulos. **Tinta tenue** (`tinta-tenue`): deshabilitado, pistas de campo, etiquetas y cuadrícula de la gráfica.
- **Papel** (`papel`): fondo de pantalla. **Hoja** (`hoja`): tarjetas, campos, barra superior, hojas y diálogos.
- **Relleno** (`relleno`): botón secundario, botón deshabilitado y menú elegido (gris claro).
- **Regla** (`regla`): borde de tarjeta, separadores y superficie de presión. **Regla fuerte** (`regla-fuerte`): borde de campos y asa de la hoja inferior.
- **Grafito** (`grafito`) y sus textos (`sobre-grafito`, `sobre-grafito-suave`): solo el aviso temporal y las descripciones emergentes.
- **Velos** (`velo`, `velo-hoja`, `velo-grafito`): superficies traslúcidas de lo que flota sobre el contenido, con desenfoque detrás.

### Named Rules
**La regla del acento con sentido.** El morado es para lo que se puede tocar, lo elegido o el dato vigente. Si un elemento morado no es ninguna de esas cosas, se vuelve gris.

**La regla del error sin rojo.** El error no usa rojo: va en tinta, con borde doble y marca de cuadrado lleno. `baja` es una dirección de precio, nunca un estado de error.

**La regla de la flecha y el signo.** `alza` y `baja` nunca van sin flecha y sin signo; el color confirma, no informa.

## Typography

**Texto:** Inter (`Inter`; pesos 400, 500, 600 y 700). **Cifras:** JetBrains Mono (`JetBrainsMono`; pesos 400, 500 y 600). Ambas OFL 1.1, empaquetadas en `assets/fonts/`.

**Character:** Inter da una interfaz limpia y neutra; JetBrains Mono, en todo lo que es número, alinea las columnas y le da al panel su tono financiero. `estiloDeCifra(...)` pasa cualquier estilo a monoespaciada tabular.

### Hierarchy
- **Cifra grande** (JetBrains Mono 600, 30 px): el valor principal de una pantalla (`CifraUsd` grande). Se achica con `FittedBox` antes que cortarse.
- **Headline small** (Inter 600, 20 px): título de pantalla y de la barra superior. **Title medium** (Inter 600, 16 px): título de tarjeta y de lista.
- **Body** (Inter 400; 16, 14 y 12 px): cuerpo, ayuda y nombres secundarios.
- **Label** (Inter 600, 15 px): texto de botones.
- **Cifra** (JetBrains Mono 500, 14 px): montos, cantidades, variaciones y horas en listas y tarjetas.
- **Eje** (JetBrains Mono 400, 11 px): etiquetas de los ejes de la gráfica.

### Named Rules
**La regla de las cifras en monoespaciada.** Todo monto, cantidad, hora y eje va en JetBrains Mono con cifras tabulares. Dinero siempre en USD con dos decimales; en espacios chicos, abreviado (`$10.0K`, `formatearCifraCorta`).

**La regla de la letra del sistema.** El texto escala con la configuración del sistema. Solo la gráfica (dibujo) limita el de sus ejes a 1,3 y la isla de navegación el de su rótulo a 1,4.

## Layout

**Celular primero.** Una sola columna a 360–412 dp; la misma estructura crece en web. Todo se mide en múltiplos de 4 dp (`Espacio`: 4, 8, 12, 16, 20, 24, 32). Margen lateral de pantalla y relleno de tarjeta de 16 dp. Ningún control interactivo baja de 48 dp (objetivo táctil, WCAG 2.2 AA).

Una pantalla se lee de arriba abajo: barra superior blanca con su título, el contenido en tarjetas apiladas sobre papel, y la isla de navegación abajo. El contenido termina donde empieza la isla (`extendBody: false`): nada con scroll queda tapado.

En ventanas anchas (desde 840 dp) la isla pasa a un riel lateral con los mismos destinos; la tarjeta de gráfica lleva el selector de rango junto al título desde 520 dp de ancho.

**La regla de la columna de cifras libre.** El botón flotante no va sobre listas con cifras a la derecha: taparía precios y la marca de desactualizado. En esas pantallas la acción va en la tarjeta de detalle.

## Elevation & Depth

Casi plano. Los planos se separan con tonos (papel, hoja) y con el borde fino de la tarjeta; solo lo que flota sobre el contenido lleva sombra y desenfoque.

### Shadow Vocabulary
- **Tarjeta** (claro: `0 1px 2px #18181B0A`; oscuro: `0 1px 2px #00000033`): una línea apenas visible bajo la tarjeta. Una tarjeta dentro de otra superficie va sin sombra (`elevada: false`).
- **Flotante** (claro: `0 2px 4px #18181B1A, 0 8px 20px #18181B1F`): isla de navegación, botón flotante y aviso temporal.
- **Hoja** (claro: `0 -4px 28px #18181B24`): hoja inferior; la sombra sube porque la hoja entra desde abajo.

### Lo que va
- El **relleno plano** bajo la línea de una gráfica: el mismo morado a muy baja opacidad, sin degradado fuerte.
- El **desenfoque de 18** (sigma) detrás de lo que flota: isla (`velo`), aviso temporal (`velo-grafito`) y hoja inferior (`velo-hoja`).
- El **brillo gris de carga**: líneas en el lugar del dato con una banda tenue que recorre `regla` cada 1,4 s y se detiene con "quitar animaciones".

### Lo que no va
- Degradados morados decorativos o de fondo; brillos, destellos o halos; el estilo "panel de IA"; texto con degradado.
- Vidrio o desenfoque en tarjetas de contenido.
- Sombras sin desplazamiento o de color.

**La regla del velo en lo que flota.** El desenfoque solo va detrás de lo que flota sobre el contenido. El contenido mismo (tarjetas, listas, avisos en línea) es opaco.

## Shapes

Esquinas suaves: 8 dp (`Radios.hoja`) en tarjetas, botón flotante, hojas y diálogos; 6 dp (`Radios.control`) en botones, campos, avisos y descripciones emergentes. Son píldora la isla de navegación, su pestaña actual, el chip de estado y la opción elegida del selector de rango.

Los bordes son reglas de 1 px (`regla` en tarjetas, `regla-fuerte` en campos). La forma de la línea es un lenguaje propio (`FormaDeLinea`): **fina** (información), **sólida** (en vivo, hecho), **discontinua** (pendiente, advertencia), **punteada** (desactualizado), **doble** (error) y **tachada** (deshabilitado).

## Components

### Buttons
- **Shape:** esquinas de 6 dp, alto mínimo de 48 dp y ancho mínimo de 64 dp.
- **Primario:** sólido en `morado` con texto `sobre-morado`, 20 dp de relleno lateral. Deshabilitado: fondo `relleno`, texto `tinta-tenue` y borde `regla`.
- **Secundario:** fondo `relleno` (gris claro) sin contorno, texto en tinta; deshabilitado con borde `regla`.
- **Texto:** texto en `morado`, 12 dp laterales.
- **Presión y foco:** superficie `regla` con onda; foco de teclado con borde morado de 2 px.
- **Enviando:** el botón se deshabilita y dice "Procesando…" con un indicador circular de 16 dp en `tinta-tenue`.
- **Flotante:** `morado`, esquinas de 8 dp, sombra flotante. Nunca sobre una lista con cifras a la derecha.

### Chips
- **Style:** píldora de 32 dp de alto, fondo hoja, borde fino, un trazo corto de la forma del estado y el rótulo en mayúsculas.
- **State:** en vivo (línea sólida), pendiente (discontinua), desactualizado (punteada), deshabilitado (texto tachado y tenue). El **destacado** (lo vigente, p. ej. "Abierto · hoy") lleva fondo `morado-tenue` y borde y texto en `morado`, como la insignia "Recommended" de Alpaca.

### Selector de rango (`SelectorDeRango`)
Botones de texto **1D · 1M · 1Y · All** en monoespaciada. El elegido lleva una píldora `morado-tenue` con texto `morado` en negrita (se reconoce también por el peso). Cada opción mide al menos 48 dp; en el celular se reparte a todo el ancho de la tarjeta. Lo lee el lector de pantalla como grupo "Rango de la gráfica", con "Un día", "Un mes", "Un año" y "Todo el período". Con `alElegir: null` quedan deshabilitados.

### Opciones excluyentes
- **Uso:** elegir una entre dos y cuatro opciones que caben a la vez (por ejemplo, el rol de una invitación).
- **Style:** rótulo encima como el de un campo y debajo las opciones en línea, que pasan a la línea siguiente si no caben. Cada una mide al menos 48 dp de alto y 64 dp de ancho, con relleno lateral de 16 dp, hoja de fondo, borde `regla-fuerte` y esquinas de 6 dp.
- **Elegida:** borde sólido de 2 px, un visto de 18 dp y el fondo `morado-tenue`; la forma del borde y el visto la distinguen aunque no se vea el color.
- **Deshabilitadas:** borde `regla` y texto `tinta-tenue`. El lector de pantalla las lee como opciones de un grupo excluyente, con su estado.

### Cards / Containers
- **Corner Style:** 8 dp. **Background:** hoja sobre papel. **Border:** `regla` de 1 px. **Shadow:** la de tarjeta, o ninguna dentro de otra superficie. **Internal Padding:** 16 dp.

### Inputs / Fields
- **Style:** etiqueta encima en seminegrita, campo con fondo hoja, borde de 1 px, esquinas de 6 dp, relleno 12 × 14 dp, ayuda en body small.
- **Focus:** borde morado de 2 px y cursor morado.
- **Error:** borde doble en tinta (2 dp; 2,5 dp con foco) y mensaje en tinta con su marca; el texto sale de `traducirError` (`docs/06` §9, `docs/04` §11). **Deshabilitado:** borde `regla`.
- **Contraseña:** con `oculto`, lo escrito se esconde y se apagan las sugerencias y la corrección.

### Navigation
- **Barra superior** (`BarraSuperior`): blanca (`hoja`) con borde inferior de 1 px, título en Inter 20 px, íconos en tinta y barra de estado que sigue al tema. Puede llevar debajo la franja de la jornada.
- **Isla de navegación** (teléfono; `BarraDePestanas`): cápsula flotante de 56 dp de alto, centrada abajo, a 16 dp de los bordes y del área segura, sobre el velo con desenfoque y sombra flotante. La pestaña actual lleva ícono y rótulo en tinta dentro de una píldora `morado-tenue`, con foco de teclado de borde morado; las demás, solo el ícono en `tinta-suave`. Al cambiar de pestaña la píldora se mueve en 200 ms (sin animación si el sistema pide quitarlas). Cada destino mide al menos 48 dp, tiene foco de teclado y conserva su nombre completo para el lector de pantalla. El rótulo escala hasta 1,4 y se recorta con puntos suspensivos si no cabe.
- **Menú por rol** (`CascaronDeNavegacion`): cada rol ve solo sus destinos, en este orden: **Usuario** Mercado, Oportunidades, Mi cupo, Alertas; **Analista** Mercado, Oportunidades, Alertas; **Administrador** Mercado, Oportunidades, Alertas, Administración. Los destinos de otro rol no aparecen deshabilitados: no aparecen. Nunca más de cuatro; Nueva orden manual no es pestaña.
- **Riel de navegación** (desde 840 dp): `NavigationRail` con ícono y rótulo siempre visibles, los mismos destinos y el elegido sobre fondo `relleno` redondeado. Sin la isla.

### Avisos
- **Información (franja):** fondo `morado-tenue`, ícono "i" de línea a la izquierda y texto en tinta; sin borde de color.
- Los demás van en hoja con texto en tinta y se reconocen por la forma de su marca (30 dp) y de su borde, nunca por el color: **Hecho** (círculo lleno con visto, borde sólido), **Advertencia** (rombo con "!", borde discontinuo), **Error** (cuadrado lleno con equis, borde doble, región viva para el lector de pantalla) y **Desactualizado** (círculo punteado con reloj, borde punteado).
- El **aviso temporal** va sobre `velo-grafito` con desenfoque, sombra flotante, esquinas de 6 dp y alto mínimo de 48 dp; lo que exige decidir va en un diálogo (D-61), no aquí.

### Diálogo de confirmación
Componente común (`DialogoDeConfirmacion` y `confirmarAccion`) de lo que toca dinero: aprobar una sugerencia, crear una orden manual, registrar un movimiento. Es el diálogo de D-61, sin biometría, en móvil y en web.
- **Forma:** diálogo de 8 dp sobre `hoja`, título, una línea opcional de detalle en `tinta-suave` y dos filas, **símbolo** y **monto**, con el rótulo a la izquierda y el valor a la derecha (el monto en `CifraUsd`). Con texto grande el valor baja a su línea.
- **Acciones:** "Cancelar" (botón de texto) y la acción (botón primario, con el verbo de la operación: "Comprar", no "Aceptar").
- **Estados** (`docs/08` §9.3): confirmando, enviando, hecho, cancelado y error. Enviando: el botón dice "Procesando…" y "Cancelar" se deshabilita; no se puede cerrar el diálogo. Error: aviso de error en línea con el texto de `traducirError`; el botón queda activo para reintentar.
- **Nunca** actualización optimista de dinero: el diálogo solo cierra en "hecho" cuando la acción respondió.

### Pantalla de ingreso
Barra superior blanca con "RiTech Inversiones" y una tarjeta sobre papel (máximo 420 dp, alineada arriba): título "Entra con tu cuenta de Google" (headline small), ayuda en `tinta-suave` ("Solo pueden entrar las personas que invitó el administrador. Usa la cuenta de Google con la que te invitaron."), el aviso en línea si hay fallo, un único botón primario morado de ancho completo "Entrar con Google" y, fuera de la tarjeta, "MVP en paper trading: una persona siempre aprueba." en `tinta-tenue`. Sin logotipo ni ilustración; el error va con borde doble, sin rojo.
- **Solo con `MODO_PRUEBAS`** (CI y local): bajo una regla y el rótulo "SOLO PRUEBAS", los campos "Correo" y "Contraseña" y un botón secundario "Entrar con correo". Sin `MODO_PRUEBAS` ese bloque no existe en el árbol.
- **Falta configuración** (solo desarrollo): aviso de advertencia y el botón deshabilitado.
- Los textos de los fallos son los de `docs/04` §11; los de arriba (título, ayuda, pie, rótulos) son decisión de tono de esta pantalla. Ninguno habla de "cuenta corporativa" ni "de RiTech".

### Marcador de sección
Mientras la historia de una sección del MVP corto no construye su pantalla, su destino abre un marcador: `BarraSuperior` con el nombre de la sección y una `Tarjeta` (máximo 560 dp, alineada arriba) con un `EstadoVacio`: "Aún no está disponible" y "Esta sección se habilita en una próxima entrega." Sin botón, sin ícono decorativo y sin números de historia.

### Pantalla de cuenta suspendida
Misma estructura que la pantalla de ingreso, **sin menú**: barra superior con "RiTech Inversiones" y una tarjeta (máximo 420 dp) con el título "Cuenta suspendida", el texto de `docs/04` §11 "Tu cuenta está suspendida. Comunícate con el administrador." y un botón secundario "Cerrar sesión" de ancho completo, que dice "Procesando…" mientras cierra. Sin aviso de error ni rojo; si el cierre falla, el botón vuelve sin mensaje técnico.

### Cifras
- **Dinero:** USD con dos decimales en JetBrains Mono tabular; desactualizado, subrayado punteado y `tinta-suave`.
- **Variación:** flecha de 16 dp, signo y color de dirección, en monoespaciada.
- **Antigüedad del dato:** trazo de 12 dp (sólido reciente, punteado desactualizado) y "hace 8 s" o "desactualizado · 2 min".

### Calendario del mercado
Mes de lunes a domingo, encabezado de días en label, hoy en un círculo morado, el periodo elegido en tinta, fines de semana en `tinta-tenue`, festivos rayados con su marca y media jornada con media luna, cada marca con su leyenda en palabras. El selector de periodo abre en la hoja inferior.

### Franja de la jornada
Sobre la barra superior blanca: eje de 1 px con marcas por hora, horas de apertura y cierre en los extremos y horas pares intermedias, todas en monoespaciada; lo transcurrido en trazo grueso de 4 px en tinta sobre un relleno gris plano; aguja de 2,5 px y hora de "ahora" en `morado`. Horas en hora de Bogotá; apertura y cierre vienen del calendario del broker. El lector de pantalla lee "Jornada de 09:30 a 16:00, hora de Bogotá. Ahora 11:46".

### Gráfica de línea (`GraficaDeLinea`)
**La pieza más importante del sistema.** API simple: `GraficaDeLinea(serie: [...], descripcion: '...')`; opcionales `referencia`, `ahora`, `alto`, `rejilla`, `mostrarEjeY`, `formatoY` y `etiquetasX`.
- **Línea:** una sola, de 2 px, en `morado`, con extremos redondeados; sin puntos ni leyenda.
- **Relleno:** plano y muy suave bajo la línea (el mismo morado a baja opacidad).
- **Cuadrícula:** líneas horizontales punteadas en `regla`, sin ejes dibujados.
- **Ejes:** etiquetas pequeñas (11 px) en monoespaciada y `tinta-tenue`. Pocas a propósito: 3 a 4 marcas en Y (`formatoY`, por defecto `$10.0K`) y 2 o 3 en X (`etiquetasX`, p. ej. `['7 AM', '10 AM', '1 PM']`), para que no se amontonen en 360 dp.
- **Referencia:** serie opcional en gris discontinuo (p. ej. QQQ frente a QLD). **Ahora:** marca opcional de 2 px en tinta, y la serie se reparte hasta ahí.
- **Accesible:** `descripcion` es lo que lee el lector de pantalla ("QLD hoy: sube de 96,02 a 98,14"); el texto de los ejes escala hasta 1,3.

**Variante de mercado.** `GraficaDeMercado` (`lib/features/mercado/`) dibuja con los mismos tokens (línea de 2 px, relleno suave, cuadrícula punteada, ejes en JetBrains Mono) y agrega la marca al deslizar el dedo, con el valor y la hora del punto. Usa el `SelectorDeRango` y el enum `RangoDeGrafica` compartidos; no tiene selector propio.

### Tarjeta de gráfica (`TarjetaDeGrafica`)
Compone lo anterior como en el panel de Alpaca: título a la izquierda y botón de refrescar opcional (48 dp); debajo, el **valor grande** en monoespaciada con el cambio (flecha y signo) pegado a la izquierda y la fecha y hora a la derecha; la gráfica a todo el ancho y el `SelectorDeRango` debajo. Desde 520 dp de ancho el selector sube a la derecha del título. API: `TarjetaDeGrafica(titulo, serie, descripcion, rango, alElegirRango, valor, cambio, fecha, ...)`. La pantalla de mercado (HU-030) y toda otra con una serie en el tiempo la usan tal cual: no dibujan gráficas sueltas.

### Movimiento
Solo cambian estados: 150 ms (`Duracion.estado`) y 200 ms (`Duracion.transicion`). Nada se anima para decorar. El brillo de carga es la única animación continua y se detiene con "quitar animaciones".

## Do's and Don'ts

### Do:
- **Do** usa solo los tokens de `lib/app/tema.dart` y los componentes de `lib/shared/widgets/`; ninguna pantalla define colores, tamaños ni fuentes sueltos.
- **Do** pon toda cifra (monto, cantidad, hora, eje) en monoespaciada con `estiloDeCifra` o `CifraUsd`.
- **Do** muestra cualquier serie en el tiempo con `TarjetaDeGrafica` o `GraficaDeLinea`.
- **Do** diseña primero para 360–412 dp y comprueba que no desborde con el texto al doble.
- **Do** acompaña cada variación de precio con flecha y signo; `alza` y `baja` solo para esa dirección.
- **Do** distingue estados y avisos por la forma de la línea y de la marca, no por el color.
- **Do** pon desenfoque detrás de lo que flota sobre el contenido (isla de navegación, aviso temporal, hoja inferior).
- **Do** muestra la carga con el brillo gris en el lugar del dato y detenlo con "quitar animaciones".
- **Do** usa esquinas de 8 dp en tarjetas y hojas, de 6 dp en controles; mide en múltiplos de 4 dp con objetivos táctiles de 48 dp.
- **Do** mantén el movimiento entre 150 y 200 ms y solo para cambios de estado.
- **Do** pon la acción en la tarjeta de detalle cuando la pantalla es una lista con cifras a la derecha.
- **Do** mantén cada par de texto en ≥ 4,5:1 en claro y oscuro (lo mide `test/app/tema_test.dart`) y agrega el par nuevo a esa prueba.
- **Do** toma los textos de error de `docs/06` §9 y `docs/04` §11 vía `traducirError`; nunca el texto crudo de una excepción.

### Don't:
- **Don't** uses morado como decoración: ni degradados ni fondos morados.
- **Don't** uses brillos, destellos o halos, ni el estilo "panel de IA", ni texto con degradado.
- **Don't** pongas vidrio o desenfoque en tarjetas de contenido.
- **Don't** uses sombras sin desplazamiento o de color.
- **Don't** uses la caja tintada roja con ícono rojo para un error ni para ningún aviso.
- **Don't** uses verde neón sobre negro ni la estética de tablero de trading.
- **Don't** pongas el botón flotante sobre listas con cifras a la derecha.
- **Don't** dejes que el color sea la única señal de un estado o una variación.
- **Don't** copies logo, íconos ni fuentes de Alpaca.
