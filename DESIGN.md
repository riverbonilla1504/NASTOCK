---
name: RiTech Inversiones
description: Almanaque en grises; la jornada del mercado como estructura y el color solo en los datos.
colors:
  grafito: "#27272A"
  sobre-grafito: "#F4F4F5"
  sobre-grafito-suave: "#B4B4BC"
  morado-sobre-grafito: "#C2B3FF"
  tinta: "#18181B"
  tinta-suave: "#52525B"
  tinta-tenue: "#6B6B74"
  papel: "#F2F2F3"
  hoja: "#FFFFFF"
  regla: "#18181B1F"
  regla-fuerte: "#18181B4D"
  morado: "#6A45E0"
  morado-tenue: "#ECE8FD"
  sobre-morado: "#FFFFFF"
  alza: "#2D6A4F"
  baja: "#A3383C"
  grafito-degradado-arriba: "#35353A"
  grafito-degradado-abajo: "#232326"
  velo: "#FFFFFFE6"
  velo-hoja: "#FFFFFFF7"
  velo-grafito: "#27272AE0"
  grafito-oscuro: "#26262A"
  sobre-grafito-suave-oscuro: "#A9A9B2"
  tinta-oscuro: "#EDEDEF"
  tinta-suave-oscuro: "#A1A1AA"
  tinta-tenue-oscuro: "#8B8B94"
  papel-oscuro: "#111113"
  hoja-oscuro: "#1C1C1F"
  regla-oscuro: "#EDEDEF1F"
  regla-fuerte-oscuro: "#EDEDEF4D"
  morado-oscuro: "#B3A1FF"
  morado-tenue-oscuro: "#2E2850"
  sobre-morado-oscuro: "#18181B"
  alza-oscuro: "#7FC9A0"
  baja-oscuro: "#F0908F"
  grafito-degradado-arriba-oscuro: "#303035"
  grafito-degradado-abajo-oscuro: "#1E1E22"
  velo-oscuro: "#1C1C1FE0"
  velo-hoja-oscuro: "#1C1C1FF5"
  velo-grafito-oscuro: "#3A3A40EB"
typography:
  display:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "44px"
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: "0em"
    fontFeature: "tnum"
  display-medium:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.1
    fontFeature: "tnum"
  cifra-grande:
    fontFamily: "Archivo, sans-serif"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: 1.15
    fontFeature: "tnum"
  headline-large:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.1
    fontFeature: "tnum"
  headline:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: 1.15
    fontFeature: "tnum"
  headline-small:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1.2
    fontFeature: "tnum"
  title:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.25
    fontFeature: "tnum"
  title-medium:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.35
    fontFeature: "tnum"
  title-small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.35
    fontFeature: "tnum"
  body:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
    fontFeature: "tnum"
  body-medium:
    fontFamily: "Archivo, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    fontFeature: "tnum"
  body-small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
    fontFeature: "tnum"
  label:
    fontFamily: "Archivo, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.2
    fontFeature: "tnum"
  label-medium:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.6px"
    fontFeature: "tnum"
  label-small:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.5px"
    fontFeature: "tnum"
  rotulo-pestana:
    fontFamily: "ArchivoCondensado, Archivo, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
    fontFeature: "tnum"
rounded:
  control: "4px"
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
    backgroundColor: "{colors.tinta}"
    textColor: "{colors.papel}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 20px"
    height: "48px"
  boton-primario-deshabilitado:
    backgroundColor: "{colors.regla}"
    textColor: "{colors.tinta-tenue}"
    rounded: "{rounded.control}"
    height: "48px"
  boton-secundario:
    backgroundColor: "transparent"
    textColor: "{colors.tinta}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 20px"
    height: "48px"
  boton-texto:
    backgroundColor: "transparent"
    textColor: "{colors.tinta}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "48px"
  boton-flotante:
    backgroundColor: "{colors.tinta}"
    textColor: "{colors.papel}"
    typography: "{typography.label}"
    rounded: "{rounded.hoja}"
  tarjeta:
    backgroundColor: "{colors.hoja}"
    rounded: "{rounded.control}"
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
    typography: "{typography.label-medium}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "32px"
  chip-de-estado-destacado:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.tinta}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "32px"
  barra-superior:
    backgroundColor: "{colors.grafito}"
    textColor: "{colors.sobre-grafito}"
    typography: "{typography.headline-small}"
    height: "56px"
  barra-de-pestanas:
    backgroundColor: "{colors.velo}"
    textColor: "{colors.tinta-suave}"
    typography: "{typography.rotulo-pestana}"
    height: "80px"
  barra-de-pestanas-actual:
    backgroundColor: "{colors.morado-tenue}"
    textColor: "{colors.tinta}"
  aviso-en-linea:
    backgroundColor: "{colors.hoja}"
    textColor: "{colors.tinta}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
    padding: "12px 12px 12px 14px"
  aviso-temporal:
    backgroundColor: "{colors.velo-grafito}"
    textColor: "{colors.sobre-grafito}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
    padding: "0 4px 0 16px"
  hoja-inferior:
    backgroundColor: "{colors.velo-hoja}"
    rounded: "{rounded.hoja}"
---

# Design System: RiTech Inversiones

## Overview

> **Quién manda.** DESIGN.md manda en lo visual (tokens, color, tipografía, componentes, movimiento y tono visual) por la decisión D-67; `docs/` manda en reglas de negocio, flujos, permisos, datos y textos de error; si chocan en algo no visual, manda `docs/`. Toda pantalla nueva usa los tokens de `lib/app/tema.dart` y los componentes de `lib/shared/widgets/`, con `/impeccable shape` antes y `/impeccable audit` + `polish` al final (`docs/15` §12).

**Creative North Star: "El Almanaque"**

El mercado es cuestión de horas: la jornada, el día y el mes son la estructura visible de la app, y cada cifra dice de cuándo es. La interfaz es un almanaque impreso en grises: papel gris claro, hojas blancas, tinta casi negra, reglas de 1 px y una barra superior en grafito que lleva la firma del sistema, la **franja de la jornada** (09:30–16:00 en hora de Bogotá, lo transcurrido en trazo grueso con un difuminado gris y la aguja de "ahora" en morado).

El color no decora: lleva datos. El morado marca lo vigente (la línea de una gráfica, la aguja de ahora, hoy en el calendario, el foco de un campo y, en tono tenue, lo seleccionado). El verde y el rojo apagados solo dicen hacia dónde se movió un precio, y nunca solos: siempre con flecha y signo. Los estados se leen por la **forma de la línea**, no por el color, así que la app funciona igual para quien no distingue colores. La densidad es la de una lista de precios para el teléfono, con cifras tabulares alineadas en columna.

El sistema rechaza el tablero de trading en negro con verde neón, el estilo "panel de IA" con degradados morados y brillos, y la alerta genérica de caja roja con ícono rojo.

**Key Characteristics:**
- Interfaz gris; el color solo en los datos.
- Firma: la franja de la jornada sobre la barra grafito.
- El estado lo dice la forma de la línea (sólida, discontinua, punteada, doble, tachada).
- Archivo normal para texto y cifras; Archivo condensada para títulos y rótulos; cifras tabulares en todo.
- Esquinas de 4 dp y 8 dp, módulo de 4 dp, objetivo táctil de 48 dp.
- Profundidad suave: sombras siempre hacia abajo y desenfoque solo en lo que flota.
- Claro y oscuro con los mismos roles; WCAG 2.2 AA medido.

## Colors

Grises fríos casi neutros con un único acento morado que solo aparece donde hay un dato vigente; cada token tiene su par en oscuro (sufijo `-oscuro`) con el mismo rol.

### Primary
- **Morado de lo vigente** (`morado`): la línea de una gráfica, la aguja de ahora, hoy en el calendario, el cursor y el borde de foco de un campo (2 px). En oscuro se aclara (`morado-oscuro`) para conservar el contraste.
- **Morado tenue** (`morado-tenue`): fondo de lo seleccionado (indicador de la pestaña actual, selección de texto, chip destacado de lo vigente). Nunca un fondo de sección.
- **Morado sobre grafito** (`morado-sobre-grafito`): solo la aguja y la hora de "ahora" en la franja de la jornada.

### Secondary
- **Alza verde apagado** (`alza`) y **baja rojo apagado** (`baja`): solo la dirección de una variación de precio, siempre con flecha (↑ ↓, guion sin cambio) y signo. Una variación de 0,00 % va en `tinta-suave`.

### Neutral
- **Grafito** (`grafito`): barra superior (con su degradado gris), aviso temporal y descripciones emergentes.
- **Sobre grafito** (`sobre-grafito`) y **sobre grafito suave** (`sobre-grafito-suave`): texto, íconos, horas y marcas de la franja sobre la barra.
- **Tinta** (`tinta`): texto, botón primario, botón flotante, bordes fuertes, marcas de aviso y texto de error.
- **Tinta suave** (`tinta-suave`): texto secundario, rótulos, pestañas no actuales.
- **Tinta tenue** (`tinta-tenue`): fines de semana del calendario, texto deshabilitado, pistas de campo y la línea de referencia de una gráfica.
- **Papel** (`papel`): fondo de pantalla.
- **Hoja** (`hoja`): listas, tarjetas, campos, avisos, hojas y diálogos.
- **Regla** (`regla`): separadores de 1 px, borde de tarjeta, fondo de deshabilitado y la superficie de presión y foco de los controles.
- **Regla fuerte** (`regla-fuerte`): borde de campos y chips, asa de la hoja inferior, borde del aviso de información.
- **Velos** (`velo`, `velo-hoja`, `velo-grafito`): superficies traslúcidas de lo que flota sobre el contenido, con desenfoque detrás (ver Elevation & Depth).

### Named Rules
**La regla del color que es dato.** El color solo lleva datos. Si un elemento morado, verde o rojo no muestra un dato vigente ni una dirección de precio, se vuelve gris.

**La regla del error sin rojo.** El error no usa rojo: va en tinta, con borde doble y marca de cuadrado lleno. `baja` es una dirección de precio, nunca un estado de error.

**La regla de la flecha y el signo.** `alza` y `baja` nunca van sin flecha y sin signo; el color confirma, no informa.

## Typography

**Display Font:** Archivo condensada (`ArchivoCondensado`, ancho 78; instancias 600, 700 y 800)
**Body Font:** Archivo (ancho 100; instancias 400, 500, 600 y 700)

**Character:** Una sola familia grotesca de Omnibus-Type (OFL 1.1) en dos anchos: la condensada da a títulos y rótulos el tono de cabecera de almanaque y hace caber más en 360 dp; la normal da texto y cifras legibles. Instancias estáticas empaquetadas en `assets/fonts/archivo/`, porque Flutter no aplica de forma fiable el eje de peso de la variable.

### Hierarchy
- **Display** (condensada 800, 44 px, 1,05; y 36 px, 1,1): cifras o títulos de máxima jerarquía; uso excepcional.
- **Cifra grande** (Archivo 600, 30 px, 1,15): el monto principal de una pantalla (`CifraUsd` grande).
- **Headline** (condensada 800; 32, 28 y 24 px): títulos de pantalla y de sección; el título de la barra superior es el de 24 px.
- **Title** (condensada 700, 20 px, 1,25): títulos de diálogo y de bloque. **Title medium/small** (Archivo 600, 16 y 14 px, 1,35): símbolo en una fila de cotización, precio normal, títulos de lista y de aviso.
- **Body** (Archivo 400; 16, 14 y 12 px; 1,45 / 1,45 / 1,4): texto de campo, cuerpo, ayuda, nombres secundarios, antigüedad del dato.
- **Label** (Archivo 600, 15 px, 1,2): texto de botones.
- **Label medium/small** (condensada 700, 12 y 11 px, espaciado 0,6 y 0,5 px): rótulos de estado en mayúsculas (chips, "ABIERTO") y encabezados de días del calendario.

### Named Rules
**La regla de las cifras tabulares.** Todos los estilos llevan `tnum` (`cifrasTabulares`): las columnas de dinero se alinean. Dinero siempre en USD con dos decimales.

**La regla del rótulo condensado.** Los rótulos de la barra de pestañas van en Archivo condensada 12 px (600, 700 en la actual) con la escala de texto limitada a 1,2: cuatro rótulos caben en 360 dp; el ícono acompaña siempre y el lector de pantalla lee el nombre completo. Fuera de esa barra, el texto escala sin límite.

## Layout

Una sola columna para el teléfono, con el mismo sistema en la web. Todo se mide en múltiplos de 4 dp (`Espacio`: 4, 8, 12, 16, 20, 24, 32). El margen lateral de pantalla y el relleno de tarjeta son de 16 dp; las filas de cotización usan 12 dp horizontales y 8 dp verticales, con un alto mínimo de 60 dp. Ningún control interactivo baja de 48 dp de alto (objetivo táctil, WCAG 2.2 AA).

La pantalla de mercado se lee de arriba abajo: barra grafito (título, estado de la jornada, franja, tiempo al cierre), luego la lista en una hoja blanca sobre papel, y la barra de pestañas de 80 dp abajo (la pantalla usa `extendBody` para que el contenido pase por detrás del velo). En una fila de cotización, símbolo y nombre ocupan la izquierda (2 partes) y precio, variación y antigüedad la derecha (3 partes).

Con texto grande, la barra superior va arriba del cuerpo y crece con su contenido; la franja de la jornada escala su alto con el texto.

**La regla de la columna de cifras libre.** El botón flotante no va sobre listas con cifras a la derecha: taparía precios y la marca de desactualizado. En esas pantallas la acción va en la tarjeta de detalle.

## Elevation & Depth

Sistema híbrido y discreto: tonos (papel, hoja, grafito) para separar planos, sombras suaves siempre desplazadas hacia abajo para despegar tarjetas y flotantes, y desenfoque de 18 (sigma) solo detrás de lo que flota sobre el contenido. Los degradados y difuminados son grises; el único degradado de color es el área bajo la línea de una gráfica, porque es dato.

### Shadow Vocabulary
- **Tarjeta** (claro: `0 1px 2px #18181B0F, 0 6px 16px #18181B0D`; oscuro: `0 1px 2px #00000066, 0 8px 20px #0000004D`): tarjetas sobre papel. Una tarjeta dentro de otra superficie va sin sombra (`elevada: false`).
- **Flotante** (claro: `0 2px 4px #18181B1F, 0 10px 24px #18181B24`; oscuro: `0 2px 6px #00000080, 0 12px 28px #00000066`): botón flotante y aviso temporal.
- **Hoja** (claro: `0 -4px 28px #18181B24`; oscuro: `0 -6px 32px #00000099`): hoja inferior; la sombra sube porque la hoja entra desde abajo.

### Degradados y difuminados que sí van
- El **área bajo la línea morada** de una gráfica: degradado vertical del morado al 24 % a transparente.
- El **degradado gris de la barra grafito**: de `grafito-degradado-arriba` a `grafito-degradado-abajo` (más clara arriba); conserva 4,5:1 con el texto en todo su recorrido.
- El **difuminado de lo transcurrido** en la franja de la jornada: gris `sobre-grafito` de 0 % a 16 % hacia "ahora", bajo el trazo grueso de 4 px.
- El **desenfoque detrás de lo que flota**: barra de pestañas (`velo`), aviso temporal (`velo-grafito`) y hoja inferior (`velo-hoja`, casi opaca porque va sobre la cortina del modal).
- Las **sombras suaves hacia abajo** del vocabulario de arriba.
- El **brillo gris de carga**: líneas en el lugar del dato con una banda `tinta` al 4 % que recorre `regla` cada 1,4 s y se detiene con "quitar animaciones".

### Lo que no va
- Degradados morados decorativos o de fondo; morado fuera de los datos.
- Brillos, destellos o halos; el estilo "panel de IA"; texto con degradado.
- Vidrio o desenfoque en tarjetas de contenido.
- Sombras sin desplazamiento o de color.

### Named Rules
**La regla de la sombra que cae.** Toda sombra es gris o negra, suave y desplazada hacia abajo (la de la hoja, hacia arriba desde el borde inferior). Sin sombras centradas, duras ni de color.

**La regla del velo en lo que flota.** El desenfoque solo va detrás de lo que flota sobre el contenido. El contenido mismo (tarjetas, listas, avisos en línea) es opaco.

## Shapes

Esquinas apenas suavizadas: 4 dp (`Radios.control`) en botones, campos, chips, tarjetas, avisos y descripciones emergentes; 8 dp (`Radios.hoja`) en el botón flotante, la parte superior de la hoja inferior y los diálogos. La única forma de píldora es el indicador de la pestaña actual (Material 3).

Los bordes son reglas de 1 px (`regla` en tarjetas, `regla-fuerte` en campos y chips). La forma de la línea es un lenguaje propio (`FormaDeLinea`): **fina** (información), **sólida** (en vivo, hecho), **discontinua** (pendiente, advertencia), **punteada** (desactualizado), **doble** (error) y **tachada** (deshabilitado). Un precio desactualizado se subraya punteado y se atenúa.

## Components

### Buttons
- **Shape:** esquinas suaves (4 dp), alto mínimo de 48 dp y ancho mínimo de 64 dp.
- **Primario:** tinta llena con texto en papel, 20 dp de relleno lateral. Deshabilitado: fondo `regla`, texto `tinta-tenue`.
- **Secundario:** contorno de 1 px en tinta, texto en tinta; deshabilitado con contorno `regla-fuerte`.
- **Texto:** texto en tinta subrayado (1,5), 12 dp laterales.
- **Presión y foco:** superficie `regla` con onda de tinta; sin cambio de color de marca.
- **Enviando:** el botón se deshabilita y dice "Procesando…" con un indicador circular de 16 dp en `tinta-tenue`.
- **Flotante:** tinta llena, esquinas de 8 dp, sombra flotante. Nunca sobre una lista con cifras a la derecha.

### Chips
- **Style:** 32 dp de alto, fondo hoja, borde `regla-fuerte`, un trazo corto de la forma del estado y el rótulo en mayúsculas (label medium).
- **State:** en vivo (línea sólida), pendiente (discontinua), desactualizado (punteada), deshabilitado (texto tachado y tenue). El **destacado** (lo vigente, p. ej. "Abierto · hoy") va en `morado-tenue` sin borde y con el trazo en morado.

### Cards / Containers
- **Corner Style:** 4 dp.
- **Background:** hoja sobre papel.
- **Shadow Strategy:** sombra de tarjeta; sin sombra dentro de otra superficie.
- **Border:** regla de 1 px.
- **Internal Padding:** 16 dp.

### Inputs / Fields
- **Style:** etiqueta encima (title small, 13 px), campo con fondo hoja, borde `regla-fuerte` de 1 px, esquinas de 4 dp, relleno 12 × 14 dp, ayuda en body small.
- **Focus:** borde morado de 2 px y cursor morado.
- **Error:** borde doble en tinta (2 dp; 2,5 dp con foco) y mensaje en tinta con su marca; el texto sale de `traducirError` (`docs/06` §9, `docs/04` §11). **Deshabilitado:** borde `regla`.

### Navigation
- **Barra superior:** grafito con su degradado gris, título condensado de 24 px en `sobre-grafito`, íconos de la barra en `sobre-grafito` y barra de estado clara.
- **Barra de pestañas:** 80 dp sobre el velo con desenfoque y una regla superior; indicador de píldora en `morado-tenue`; ícono y rótulo en tinta en la pestaña actual y en `tinta-suave` en las demás. En ventanas anchas, riel de navegación con los mismos roles.

### Avisos
Siempre en hoja con texto en tinta; cada tipo se reconoce por la forma de su marca (30 dp) y de su borde, nunca por el color:
- **Información:** marca de círculo con "i", borde fino en `regla-fuerte`.
- **Hecho:** círculo lleno de tinta con visto, borde sólido.
- **Advertencia:** rombo con "!", borde discontinuo.
- **Error:** cuadrado lleno de tinta con equis, borde doble; región viva para el lector de pantalla.
- **Desactualizado:** círculo punteado con reloj, borde punteado.

El **aviso temporal** va sobre `velo-grafito` con desenfoque, sombra flotante, esquinas de 4 dp y alto mínimo de 48 dp; lo que exige decidir va en un diálogo (D-61), no aquí.

### Cifras
- **Dinero:** USD con dos decimales en cifras tabulares; desactualizado, subrayado punteado y `tinta-suave`.
- **Variación:** flecha de 16 dp, signo y color de dirección, en 14 px 600.
- **Antigüedad del dato:** trazo de 12 dp (sólido reciente, punteado desactualizado) y "hace 8 s" o "desactualizado · 2 min".

### Calendario del mercado
Mes de lunes a domingo, encabezado de días en label medium sobre una regla de tinta: hoy en un círculo morado, el periodo elegido en tinta, fines de semana en `tinta-tenue`, festivos rayados con su marca y media jornada con media luna, cada marca con su leyenda en palabras. El selector de periodo abre en la hoja inferior.

### Franja de la jornada (firma)
Sobre la barra grafito: eje de 1 px en `sobre-grafito-suave` con marcas por hora, horas de apertura y cierre en los extremos y horas pares intermedias en body small; lo transcurrido en trazo de 4 px en `sobre-grafito` con su difuminado gris; aguja de 2,5 px y hora de "ahora" (700) en `morado-sobre-grafito`. Horas en hora de Bogotá; apertura y cierre vienen del calendario del broker. El lector de pantalla lee "Jornada de 09:30 a 16:00, hora de Bogotá. Ahora 11:46".

### Gráfica de línea
Línea de 2,5 px en morado con extremos redondeados, punto de 4 dp en el último dato, área en degradado morado a transparente, línea de referencia discontinua en `tinta-tenue`, base en `regla-fuerte` y marca de ahora de 2 px en tinta.

### Movimiento
Solo cambian estados: 150 ms (`Duracion.estado`) y 200 ms (`Duracion.transicion`). Nada se anima para decorar. El brillo de carga es la única animación continua y se detiene con "quitar animaciones".

## Do's and Don'ts

### Do:
- **Do** usa solo los tokens de `lib/app/tema.dart` y los componentes de `lib/shared/widgets/`; ninguna pantalla define colores, tamaños ni fuentes sueltos.
- **Do** reserva el morado para la línea de una gráfica, la aguja de ahora, hoy en el calendario, el foco de un campo y, en tono tenue, lo seleccionado.
- **Do** acompaña cada variación de precio con flecha y signo; `alza` y `baja` solo para esa dirección.
- **Do** distingue estados y avisos por la forma de la línea y de la marca (círculo, círculo lleno, rombo, cuadrado lleno, círculo punteado; fino, sólido, discontinuo, doble, punteado).
- **Do** pon el área bajo la línea morada de una gráfica en degradado del morado a transparente: es dato.
- **Do** usa el degradado gris de la barra grafito (más clara arriba) y el difuminado gris de lo transcurrido en la franja de la jornada.
- **Do** pon desenfoque detrás de lo que flota sobre el contenido (barra de pestañas, aviso temporal, hoja inferior).
- **Do** usa sombras suaves siempre desplazadas hacia abajo en tarjetas, flotantes y hojas.
- **Do** muestra la carga con el brillo gris en el lugar del dato y detenlo con "quitar animaciones".
- **Do** usa esquinas de 4 dp en controles, tarjetas y avisos, y de 8 dp en el botón flotante y las hojas; mide en múltiplos de 4 dp con objetivos táctiles de 48 dp.
- **Do** mantén el movimiento entre 150 y 200 ms y solo para cambios de estado.
- **Do** pon la acción en la tarjeta de detalle cuando la pantalla es una lista con cifras a la derecha.
- **Do** mantén cada par de texto en ≥ 4,5:1 en claro y oscuro (WCAG 2.2 AA; lo mide `test/app/tema_test.dart`) y agrega el par nuevo a esa prueba.
- **Do** toma los textos de error de `docs/06` §9 y `docs/04` §11 vía `traducirError`; nunca el texto crudo de una excepción.

### Don't:
- **Don't** uses degradados morados decorativos o de fondo, ni morado fuera de los datos.
- **Don't** uses brillos, destellos o halos, ni el estilo "panel de IA".
- **Don't** uses texto con degradado.
- **Don't** pongas vidrio o desenfoque en tarjetas de contenido.
- **Don't** uses sombras sin desplazamiento o de color.
- **Don't** uses la caja tintada roja con ícono rojo para un error ni para ningún aviso.
- **Don't** uses verde neón sobre negro ni la estética de tablero de trading.
- **Don't** pongas el botón flotante sobre listas con cifras a la derecha.
- **Don't** dejes que el color sea la única señal de un estado o una variación.
