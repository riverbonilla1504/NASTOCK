# Contrato: componentes del sistema de diseño

Interfaz pública de `lib/shared/widgets/` y de `lib/app/tema.dart`. Las pantallas de las demás historias usan solo esto (15 §12). Los textos de ejemplo de esta página no son reglas: cada historia pone los suyos desde `docs/`.

## Tema (`lib/app/tema.dart`)

| Símbolo | Qué es |
|---|---|
| `crearTema()` · `crearTemaOscuro()` | `ThemeData` claro y oscuro con Material 3, Archivo y los colores del Almanaque |
| `ColoresAlmanaque` | `ThemeExtension` con los colores con nombre: `grafito`, `sobreGrafito`, `sobreGrafitoSuave`, `moradoSobreGrafito`, `tinta`, `tintaSuave`, `tintaTenue`, `papel`, `hoja`, `regla`, `reglaFuerte`, `morado`, `moradoTenue`, `sobreMorado`, `alza`, `baja` |
| `context.colores` | Atajo a la extensión del tema actual |
| `Espacio`, `Radios`, `Duracion`, `Familias` | Medidas (múltiplos de 4 dp), radios (4 y 8), duraciones (150 y 200 ms) y familias tipográficas |

## Componentes (`lib/shared/widgets/`)

| Componente | Constructor | Estados |
|---|---|---|
| `BotonPrimario`, `BotonSecundario`, `BotonTexto` | `(texto, alPresionar, {icono, enviando})` | normal, presionado, foco, deshabilitado (`alPresionar` nulo), enviando ("Procesando…", deshabilitado; 08 §9.3) |
| `Tarjeta` | `({child, padding, alTocar})` | normal, tocable |
| `Campo` | `({etiqueta, controlador, ayuda, error, teclado, icono, alCambiar, soloLectura, alTocar})` | normal, foco (borde morado), error (borde doble en tinta y mensaje con marca), solo lectura |
| `AvisoEnLinea` | `({tipo, mensaje, titulo, accion, alAccionar})` · `AvisoEnLinea.deError(error, {titulo, accion, alAccionar})` | `TipoAviso.informacion`, `exito`, `advertencia`, `error`, `desactualizado`: cada uno con su marca y su borde |
| `mostrarAvisoTemporal` | `(context, mensaje, {accion, alAccionar})` | aviso pasajero en la parte inferior |
| `EstadoVacio` | `({titulo, mensaje, accion})` | — |
| `EstadoCargando` | `({lineas})` | líneas de carga en el lugar del dato |
| `EstadoDeError` | `({error, alReintentar})` | texto siempre traducido por `traducirError` |
| `MensajeDeError` | `({error})` | igual que TT-04; ahora se dibuja como aviso de error |
| `CifraUsd` | `(monto, {tamano, desactualizada})` | normal, desactualizada (subrayado punteado) |
| `Variacion` | `(porcentaje)` | alza, baja, sin cambio: flecha, signo y color |
| `AntiguedadDelDato` | `(antiguedad, {desactualizado})` | reciente (línea sólida), desactualizado (línea punteada) |
| `ChipDeEstado` | `({etiqueta, forma, destacado})` · `.enVivo()`, `.pendiente()`, `.desactualizado()`, `.deshabilitado()` | la línea dice el estado |
| `GraficaDeLinea` | `({serie, referencia, ahora, alto, descripcion})` | serie en morado, referencia en gris discontinuo, aguja de ahora |
| `TarjetaDeCotizacion` | `({simbolo, nombre, precio, variacion, antiguedad, desactualizado, curva, ahora, acciones})` | normal, desactualizada |
| `CalendarioDelMercado` | `({mes, hoy, festivos, mediasJornadas, seleccion, alElegirDia, alCambiarMes, primerDia, ultimoDia})` | hoy, periodo, fin de semana, festivo, media jornada, fuera de rango |
| `mostrarSelectorDePeriodo` | `(context, {inicial, hoy, festivos, mediasJornadas, primerDia, ultimoDia})` → `Future<DateTimeRange?>` | hoja inferior con Cancelar y Listo |
| `CampoDePeriodo` | `({etiqueta, periodo, alCambiar, hoy, festivos, mediasJornadas, primerDia, ultimoDia, ayuda})` | campo de solo lectura que abre el selector |
| `FranjaDeLaJornada` | `({apertura, cierre, ahora})` | jornada en curso, antes de abrir, cerrada |

Los festivos y las medias jornadas los pone quien usa el calendario: vienen del calendario del broker (RN-41, HU-027).
