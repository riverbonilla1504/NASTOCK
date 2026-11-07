# Investigación (Fase 0): HU-116 · Identidad visual y sistema de diseño

No quedó ninguna duda sin resolver. Estas son las decisiones de diseño y cómo se resolvieron. Ninguna cambia una regla de negocio: lo visual lo gobierna `DESIGN.md` (D-67).

## R-1 · Archivo como instancias estáticas, recortadas al latín

- **Decisión**: la fuente es Archivo (Omnibus-Type, licencia OFL, sin nombre reservado), descargada de `github.com/google/fonts` (`ofl/archivo`) el 2026-11-06. Se guardan siete instancias estáticas, generadas con `fontTools`: Archivo 400, 500, 600 y 700 (ancho 100) y ArchivoCondensado 600, 700 y 800 (ancho 78). Se recortan al latín (U+0020–U+024F, puntuación, monedas, flechas, `−` y `×`) y conservan sus funciones OpenType, entre ellas las cifras tabulares (`tnum`). Unos 76 KB cada una.
- **Razón**: una familia con eje de ancho da títulos condensados y texto normal sin mezclar familias; las cifras tabulares alinean las columnas de dinero. Las instancias estáticas evitan que el peso dependa de cómo cada plataforma aplica los ejes de una fuente variable.
- **Alternativas**: Poppins (descartada por D-67: es la fuente de la v2 y sus formas anchas gastan espacio en listas densas); la fuente variable completa de 658 KB (descartada por el riesgo con los pesos y por el tamaño); cargarla de Google Fonts (prohibido: nada de servicios externos).

## R-2 · La interfaz es gris y el color solo lleva datos

- **Decisión**: fondos, superficies, bordes, texto, botones, avisos y chips van en grises. El morado (#6A45E0 en claro, #B3A1FF en oscuro) es la línea de una gráfica, la aguja de "ahora", el día de hoy, el foco de un campo y, en tono tenue, lo seleccionado. Verde y rojo apagados solo marcan la dirección de una variación de precio, siempre con flecha y signo.
- **Razón**: lo pidió Javier ("tonalidades grises y un morado para las líneas de las gráficas") y aprobó el mock con las variaciones en verde y rojo apagados.
- **Alternativas**: amarillo de tapa del primer mock (descartado por Javier); variaciones también en gris (ofrecida, Javier eligió mantenerlas).

## R-3 · Los estados se distinguen por forma, no por color

- **Decisión**: cada aviso tiene una marca de forma propia (círculo, círculo lleno, rombo, cuadrado lleno, círculo punteado) y un borde de forma propia (fino, sólido, discontinuo, doble, punteado). Los chips llevan una línea que dice el estado: sólida en vivo, discontinua pendiente, punteada desactualizado, tachada deshabilitado. El error no usa rojo.
- **Razón**: WCAG 2.2 AA (1.4.1, uso del color) y el pedido de Javier de no usar la etiqueta roja con ícono rojo.
- **Alternativas**: cajas tintadas por tipo (descartadas por el pedido de Javier).

## R-4 · Bordes discontinuos y punteados con `CustomPainter`

- **Decisión**: un pintor propio dibuja los bordes discontinuos y punteados de avisos y chips.
- **Razón**: Flutter no trae bordes discontinuos y no se agregan paquetes.
- **Alternativas**: el paquete `dotted_border` (descartado: paquete nuevo para algo de pocas líneas).

## R-5 · `MensajeDeError` conserva su interfaz

- **Decisión**: `MensajeDeError(error:)` sigue existiendo con el mismo constructor y ahora se dibuja como el aviso de error del sistema. El texto sigue saliendo de `traducirError`.
- **Razón**: TT-04 lo creó y otras ramas pueden estar usándolo; sus pruebas siguen pasando tal cual.
- **Alternativas**: borrarlo y reemplazar sus usos (descartada: rompería ramas en curso).

## R-6 · El catálogo solo existe en debug o con `MODO_PRUEBAS`

- **Decisión**: la ruta `/catalogo` se registra en el enrutador solo si la app corre en modo debug o con `MODO_PRUEBAS`. Sin la ruta, ir a `/catalogo` no encuentra pantalla.
- **Razón**: CA-10. `MODO_PRUEBAS` ya existe en `lib/core/configuracion/entorno.dart` (05 §10.1).
- **Alternativas**: ocultar solo el enlace (descartada: la pantalla seguiría accesible por la URL).

## R-7 · Calendario propio en vez de `showDateRangePicker`

- **Decisión**: un calendario de mes propio (lunes primero), presentado en una hoja inferior con Cancelar y Listo. Recibe como datos los festivos y las medias jornadas; los fines de semana se atenúan.
- **Razón**: el selector estándar de Material no puede marcar festivos ni medias jornadas ni mostrar su leyenda, y era el calendario que Javier no quería repetir de la v2.
- **Alternativas**: tematizar `showDateRangePicker` (descartada por lo anterior).

## R-8 · La gráfica se dibuja con `CustomPainter`

- **Decisión**: una gráfica de línea propia: serie principal en morado sólido, referencia opcional en gris discontinuo, rejilla gris y aguja de "ahora".
- **Razón**: alcanza para las gráficas del MVP corto sin paquetes nuevos.
- **Alternativas**: `fl_chart` (descartada: paquete nuevo).

## R-9 · Formato de porcentaje junto al de dinero

- **Decisión**: `formatearPorcentaje(1.24)` → `+1,24 %`; `-0.82` → `-0,82 %`; cero sin signo. Coma decimal, espacio antes de `%`, mismo signo `-` que `formatearUsd`.
- **Razón**: la variación se muestra en todas las cotizaciones; vive con los demás formatos en `lib/core/formato/`.
- **Alternativas**: formatear en cada widget (descartada: se repetiría).

## R-10 · Modo oscuro de primera clase

- **Decisión**: tema claro y oscuro con los mismos roles; la app sigue el modo del sistema.
- **Razón**: Android lo espera (guía de plataforma de impeccable) y el contraste se midió en ambos.
- **Alternativas**: solo claro (descartada).
