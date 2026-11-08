/// Tokens y tema de la app: dirección visual estilo Alpaca (D-69).
///
/// Lo visual lo gobierna `DESIGN.md` (D-67). La interfaz es de grises con un
/// único acento morado: botones principales, línea de gráfica, foco, avisos
/// en franja y lo seleccionado; verde y rojo apagados solo para la dirección
/// de un precio. Texto en Inter y todas las cifras en JetBrains Mono.
/// Ninguna pantalla define colores, tamaños ni fuentes sueltos: usa estos
/// tokens y los componentes de `lib/shared/widgets/` (docs/15 §12).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Familias tipográficas empaquetadas (`assets/fonts/`), ambas OFL.
abstract final class Familias {
  /// Inter: texto, títulos y controles.
  static const String texto = 'Inter';

  /// JetBrains Mono: montos, cantidades, horas y ejes de gráfica.
  static const String cifras = 'JetBrainsMono';
}

/// Medidas en múltiplos de 4 dp.
abstract final class Espacio {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;

  /// Objetivo táctil mínimo (WCAG 2.2 AA y Material).
  static const double objetivoTactil = 48;
}

/// Radios de las esquinas.
abstract final class Radios {
  /// Botones, campos, chips y avisos.
  static const double control = 6;

  /// Tarjetas, botón flotante, hojas y diálogos.
  static const double hoja = 8;
}

/// Duraciones del movimiento: solo cambian estados.
abstract final class Duracion {
  static const Duration estado = Duration(milliseconds: 150);
  static const Duration transicion = Duration(milliseconds: 200);
}

/// Cifras tabulares: las columnas de dinero se alinean.
const List<FontFeature> cifrasTabulares = [FontFeature.tabularFigures()];

/// Pasa un estilo a las cifras del sistema: JetBrains Mono tabular. Todo
/// monto, cantidad, hora y eje de gráfica lo usa (D-69).
TextStyle estiloDeCifra(TextStyle base) => base.copyWith(
  fontFamily: Familias.cifras,
  fontFeatures: cifrasTabulares,
);

/// Colores con nombre del sistema, en claro y en oscuro.
@immutable
class ColoresTema extends ThemeExtension<ColoresTema> {
  const ColoresTema({
    required this.grafito,
    required this.sobreGrafito,
    required this.sobreGrafitoSuave,
    required this.tinta,
    required this.tintaSuave,
    required this.tintaTenue,
    required this.papel,
    required this.hoja,
    required this.regla,
    required this.reglaFuerte,
    required this.relleno,
    required this.morado,
    required this.moradoTenue,
    required this.sobreMorado,
    required this.alza,
    required this.baja,
  });

  /// Aviso temporal y descripciones emergentes.
  final Color grafito;

  /// Texto sobre grafito.
  final Color sobreGrafito;

  /// Texto secundario sobre grafito.
  final Color sobreGrafitoSuave;

  /// Texto, botón primario y bordes fuertes.
  final Color tinta;

  /// Texto secundario.
  final Color tintaSuave;

  /// Fines de semana y deshabilitado.
  final Color tintaTenue;

  /// Fondo de pantalla.
  final Color papel;

  /// Listas, tarjetas y hojas.
  final Color hoja;

  /// Separadores.
  final Color regla;

  /// Bordes de campos y chips.
  final Color reglaFuerte;

  /// Gris suave: botón secundario, deshabilitado y menú elegido.
  final Color relleno;

  /// Acento: botón principal, línea de gráfica, hoy y foco.
  final Color morado;

  /// Fondo tenue del acento: lo seleccionado, avisos en franja y chips.
  final Color moradoTenue;

  /// Texto sobre morado.
  final Color sobreMorado;

  /// Variación al alza (siempre con flecha y signo).
  final Color alza;

  /// Variación a la baja (siempre con flecha y signo).
  final Color baja;

  static const ColoresTema claro = ColoresTema(
    grafito: Color(0xFF27272A),
    sobreGrafito: Color(0xFFF4F4F5),
    sobreGrafitoSuave: Color(0xFFB4B4BC),
    tinta: Color(0xFF18181B),
    tintaSuave: Color(0xFF52525B),
    tintaTenue: Color(0xFF6B6B74),
    papel: Color(0xFFF7F7F8),
    hoja: Color(0xFFFFFFFF),
    regla: Color(0xFFE4E4E7),
    reglaFuerte: Color(0xFF8E8E97),
    relleno: Color(0xFFF1F1F3),
    morado: Color(0xFF6A45E0),
    moradoTenue: Color(0xFFEFEBFD),
    sobreMorado: Color(0xFFFFFFFF),
    alza: Color(0xFF2D6A4F),
    baja: Color(0xFFA3383C),
  );

  static const ColoresTema oscuro = ColoresTema(
    grafito: Color(0xFF2E2E33),
    sobreGrafito: Color(0xFFF4F4F5),
    sobreGrafitoSuave: Color(0xFFA9A9B2),
    tinta: Color(0xFFEDEDEF),
    tintaSuave: Color(0xFFA1A1AA),
    tintaTenue: Color(0xFF8B8B94),
    papel: Color(0xFF0E0E10),
    hoja: Color(0xFF17171A),
    regla: Color(0xFF2B2B30),
    reglaFuerte: Color(0xFF6F6F78),
    relleno: Color(0xFF222226),
    morado: Color(0xFFB3A1FF),
    moradoTenue: Color(0xFF28224A),
    sobreMorado: Color(0xFF18181B),
    alza: Color(0xFF7FC9A0),
    baja: Color(0xFFF0908F),
  );

  @override
  ColoresTema copyWith({
    Color? grafito,
    Color? sobreGrafito,
    Color? sobreGrafitoSuave,
    Color? tinta,
    Color? tintaSuave,
    Color? tintaTenue,
    Color? papel,
    Color? hoja,
    Color? regla,
    Color? reglaFuerte,
    Color? relleno,
    Color? morado,
    Color? moradoTenue,
    Color? sobreMorado,
    Color? alza,
    Color? baja,
  }) {
    return ColoresTema(
      grafito: grafito ?? this.grafito,
      sobreGrafito: sobreGrafito ?? this.sobreGrafito,
      sobreGrafitoSuave: sobreGrafitoSuave ?? this.sobreGrafitoSuave,
      tinta: tinta ?? this.tinta,
      tintaSuave: tintaSuave ?? this.tintaSuave,
      tintaTenue: tintaTenue ?? this.tintaTenue,
      papel: papel ?? this.papel,
      hoja: hoja ?? this.hoja,
      regla: regla ?? this.regla,
      reglaFuerte: reglaFuerte ?? this.reglaFuerte,
      relleno: relleno ?? this.relleno,
      morado: morado ?? this.morado,
      moradoTenue: moradoTenue ?? this.moradoTenue,
      sobreMorado: sobreMorado ?? this.sobreMorado,
      alza: alza ?? this.alza,
      baja: baja ?? this.baja,
    );
  }

  @override
  ColoresTema lerp(ThemeExtension<ColoresTema>? other, double t) {
    if (other is! ColoresTema) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresTema(
      grafito: m(grafito, other.grafito),
      sobreGrafito: m(sobreGrafito, other.sobreGrafito),
      sobreGrafitoSuave: m(sobreGrafitoSuave, other.sobreGrafitoSuave),
      tinta: m(tinta, other.tinta),
      tintaSuave: m(tintaSuave, other.tintaSuave),
      tintaTenue: m(tintaTenue, other.tintaTenue),
      papel: m(papel, other.papel),
      hoja: m(hoja, other.hoja),
      regla: m(regla, other.regla),
      reglaFuerte: m(reglaFuerte, other.reglaFuerte),
      relleno: m(relleno, other.relleno),
      morado: m(morado, other.morado),
      moradoTenue: m(moradoTenue, other.moradoTenue),
      sobreMorado: m(sobreMorado, other.sobreMorado),
      alza: m(alza, other.alza),
      baja: m(baja, other.baja),
    );
  }
}

/// Profundidad: casi plana. Las tarjetas se separan con un borde fino y solo
/// lo que flota (isla de navegación, aviso temporal, hojas) lleva sombra y
/// velo traslúcido con desenfoque.
@immutable
class ProfundidadTema extends ThemeExtension<ProfundidadTema> {
  const ProfundidadTema({
    required this.sombraTarjeta,
    required this.sombraFlotante,
    required this.sombraHoja,
    required this.velo,
    required this.veloHoja,
    required this.veloGrafito,
  });

  /// Desenfoque detrás de la isla de navegación, el aviso temporal y las hojas.
  static const double desenfoque = 18;

  /// Tarjetas: una línea de sombra apenas visible, hacia abajo.
  final List<BoxShadow> sombraTarjeta;

  /// Botón flotante, isla y aviso temporal.
  final List<BoxShadow> sombraFlotante;

  /// Hojas inferiores.
  final List<BoxShadow> sombraHoja;

  /// Hoja traslúcida para superficies con desenfoque (isla de navegación).
  final Color velo;

  /// Hoja inferior: casi opaca, porque va sobre la cortina oscura del modal.
  final Color veloHoja;

  /// Grafito traslúcido para el aviso temporal.
  final Color veloGrafito;

  static const ProfundidadTema claro = ProfundidadTema(
    sombraTarjeta: [
      BoxShadow(color: Color(0x0A18181B), offset: Offset(0, 1), blurRadius: 2),
    ],
    sombraFlotante: [
      BoxShadow(color: Color(0x1A18181B), offset: Offset(0, 2), blurRadius: 4),
      BoxShadow(
        color: Color(0x1F18181B),
        offset: Offset(0, 8),
        blurRadius: 20,
      ),
    ],
    sombraHoja: [
      BoxShadow(
        color: Color(0x2418181B),
        offset: Offset(0, -4),
        blurRadius: 28,
      ),
    ],
    velo: Color(0xE6FFFFFF),
    veloHoja: Color(0xF7FFFFFF),
    veloGrafito: Color(0xE027272A),
  );

  static const ProfundidadTema oscuro = ProfundidadTema(
    sombraTarjeta: [
      BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    sombraFlotante: [
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 2), blurRadius: 6),
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 12),
        blurRadius: 28,
      ),
    ],
    sombraHoja: [
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, -6),
        blurRadius: 32,
      ),
    ],
    velo: Color(0xE017171A),
    veloHoja: Color(0xF517171A),
    veloGrafito: Color(0xEB3A3A40),
  );

  @override
  ProfundidadTema copyWith({
    List<BoxShadow>? sombraTarjeta,
    List<BoxShadow>? sombraFlotante,
    List<BoxShadow>? sombraHoja,
    Color? velo,
    Color? veloHoja,
    Color? veloGrafito,
  }) {
    return ProfundidadTema(
      sombraTarjeta: sombraTarjeta ?? this.sombraTarjeta,
      sombraFlotante: sombraFlotante ?? this.sombraFlotante,
      sombraHoja: sombraHoja ?? this.sombraHoja,
      velo: velo ?? this.velo,
      veloHoja: veloHoja ?? this.veloHoja,
      veloGrafito: veloGrafito ?? this.veloGrafito,
    );
  }

  @override
  ProfundidadTema lerp(ThemeExtension<ProfundidadTema>? other, double t) {
    if (other is! ProfundidadTema) return this;
    return ProfundidadTema(
      sombraTarjeta: BoxShadow.lerpList(sombraTarjeta, other.sombraTarjeta, t)!,
      sombraFlotante: BoxShadow.lerpList(
        sombraFlotante,
        other.sombraFlotante,
        t,
      )!,
      sombraHoja: BoxShadow.lerpList(sombraHoja, other.sombraHoja, t)!,
      velo: Color.lerp(velo, other.velo, t)!,
      veloHoja: Color.lerp(veloHoja, other.veloHoja, t)!,
      veloGrafito: Color.lerp(veloGrafito, other.veloGrafito, t)!,
    );
  }
}

/// Atajos a los tokens del tema actual.
extension ColoresDelContexto on BuildContext {
  ColoresTema get colores =>
      Theme.of(this).extension<ColoresTema>() ?? ColoresTema.claro;

  ProfundidadTema get profundidad =>
      Theme.of(this).extension<ProfundidadTema>() ??
      ProfundidadTema.claro;
}

// Construir un ThemeData es caro y el resultado no cambia: se arma una vez.
final ThemeData _temaClaro = _construir(
  ColoresTema.claro,
  ProfundidadTema.claro,
  Brightness.light,
);
final ThemeData _temaOscuro = _construir(
  ColoresTema.oscuro,
  ProfundidadTema.oscuro,
  Brightness.dark,
);

/// Tema claro (el de uso diurno, durante la jornada).
ThemeData crearTema() => _temaClaro;

/// Tema oscuro, con los mismos roles.
ThemeData crearTemaOscuro() => _temaOscuro;

TextStyle _estilo(
  double tamano,
  FontWeight peso,
  Color color, {
  String familia = Familias.texto,
  double alto = 1.4,
  double espaciado = 0,
}) {
  return TextStyle(
    fontFamily: familia,
    fontSize: tamano,
    fontWeight: peso,
    height: alto,
    letterSpacing: espaciado,
    color: color,
    fontFeatures: cifrasTabulares,
  );
}

TextTheme _textos(ColoresTema c) {
  return TextTheme(
    displayLarge: _estilo(40, FontWeight.w700, c.tinta, alto: 1.1),
    displayMedium: _estilo(32, FontWeight.w700, c.tinta, alto: 1.15),
    // Cifra grande: el valor principal de una pantalla, en monoespaciada.
    displaySmall: estiloDeCifra(_estilo(30, FontWeight.w600, c.tinta, alto: 1.15)),
    headlineLarge: _estilo(28, FontWeight.w700, c.tinta, alto: 1.15),
    headlineMedium: _estilo(24, FontWeight.w600, c.tinta, alto: 1.2),
    headlineSmall: _estilo(20, FontWeight.w600, c.tinta, alto: 1.25),
    titleLarge: _estilo(18, FontWeight.w600, c.tinta, alto: 1.3),
    titleMedium: _estilo(16, FontWeight.w600, c.tinta, alto: 1.35),
    titleSmall: _estilo(14, FontWeight.w600, c.tinta, alto: 1.35),
    bodyLarge: _estilo(16, FontWeight.w400, c.tinta, alto: 1.45),
    bodyMedium: _estilo(14, FontWeight.w400, c.tinta, alto: 1.45),
    bodySmall: _estilo(12, FontWeight.w400, c.tintaSuave, alto: 1.4),
    labelLarge: _estilo(15, FontWeight.w600, c.tinta, alto: 1.2),
    labelMedium: _estilo(
      12,
      FontWeight.w600,
      c.tintaSuave,
      alto: 1.2,
      espaciado: 0.2,
    ),
    labelSmall: _estilo(
      11,
      FontWeight.w600,
      c.tintaSuave,
      alto: 1.2,
      espaciado: 0.2,
    ),
  );
}

ThemeData _construir(
  ColoresTema c,
  ProfundidadTema p,
  Brightness brillo,
) {
  final textos = _textos(c);
  final esquina = BorderRadius.circular(Radios.control);
  final esquinaTarjeta = BorderRadius.circular(Radios.hoja);
  OutlineInputBorder borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: esquina,
        borderSide: BorderSide(color: color, width: ancho),
      );
  const alturaBoton = Size(64, Espacio.objetivoTactil);
  const rellenoBoton = EdgeInsets.symmetric(horizontal: Espacio.x5);

  final esquema = ColorScheme(
    brightness: brillo,
    primary: c.morado,
    onPrimary: c.sobreMorado,
    primaryContainer: c.moradoTenue,
    onPrimaryContainer: c.tinta,
    secondary: c.tintaSuave,
    onSecondary: c.hoja,
    secondaryContainer: c.moradoTenue,
    onSecondaryContainer: c.tinta,
    tertiary: c.morado,
    onTertiary: c.sobreMorado,
    error: c.tinta,
    onError: c.hoja,
    errorContainer: c.hoja,
    onErrorContainer: c.tinta,
    surface: c.hoja,
    onSurface: c.tinta,
    onSurfaceVariant: c.tintaSuave,
    surfaceContainerLowest: c.hoja,
    surfaceContainerLow: c.hoja,
    surfaceContainer: c.hoja,
    surfaceContainerHigh: c.hoja,
    surfaceContainerHighest: c.relleno,
    outline: c.reglaFuerte,
    outlineVariant: c.regla,
    inverseSurface: c.grafito,
    onInverseSurface: c.sobreGrafito,
    inversePrimary: c.morado,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    surfaceTint: const Color(0x00000000),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: esquema,
    fontFamily: Familias.texto,
    textTheme: textos,
    scaffoldBackgroundColor: c.papel,
    canvasColor: c.hoja,
    dividerColor: c.regla,
    extensions: [c, p],
    splashFactory: InkRipple.splashFactory,
    hoverColor: c.regla,
    focusColor: c.regla,
    highlightColor: c.regla,
    splashColor: c.regla,
    iconTheme: IconThemeData(color: c.tinta, size: 24),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.morado,
      selectionColor: c.moradoTenue,
      selectionHandleColor: c.morado,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.hoja,
      foregroundColor: c.tinta,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: c.regla)),
      systemOverlayStyle: brillo == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: c.tinta),
      actionsIconTheme: IconThemeData(color: c.tinta),
      titleTextStyle: textos.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: c.hoja,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: esquinaTarjeta,
        side: BorderSide(color: c.regla),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.regla, thickness: 1, space: 1),
    // Primario: sólido en el acento. Deshabilitado: gris con borde.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.morado,
        foregroundColor: c.sobreMorado,
        disabledBackgroundColor: c.relleno,
        disabledForegroundColor: c.tintaTenue,
        minimumSize: alturaBoton,
        padding: rellenoBoton,
        shape: RoundedRectangleBorder(borderRadius: esquina),
        textStyle: textos.labelLarge,
      ).copyWith(
        side: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? BorderSide(color: c.regla)
              : null,
        ),
      ),
    ),
    // Secundario: fondo gris claro, sin contorno.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(c.relleno),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? c.tintaTenue : c.tinta,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.disabled)
                ? c.regla
                : const Color(0x00000000),
          ),
        ),
        overlayColor: WidgetStatePropertyAll(c.regla),
        minimumSize: const WidgetStatePropertyAll(alturaBoton),
        padding: const WidgetStatePropertyAll(rellenoBoton),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: esquina),
        ),
        textStyle: WidgetStatePropertyAll(textos.labelLarge),
      ),
    ),
    // Texto: seminegrita en el acento, sin subrayado.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.morado,
        disabledForegroundColor: c.tintaTenue,
        minimumSize: alturaBoton,
        padding: const EdgeInsets.symmetric(horizontal: Espacio.x3),
        shape: RoundedRectangleBorder(borderRadius: esquina),
        textStyle: textos.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.morado,
      foregroundColor: c.sobreMorado,
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 4,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.hoja),
      ),
      extendedTextStyle: textos.labelLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.hoja,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Espacio.x3,
        vertical: 14,
      ),
      hintStyle: textos.bodyLarge!.copyWith(color: c.tintaTenue),
      helperStyle: textos.bodySmall,
      errorStyle: textos.bodySmall!.copyWith(color: c.tinta),
      prefixIconColor: c.tintaSuave,
      suffixIconColor: c.tintaSuave,
      border: borde(c.reglaFuerte),
      enabledBorder: borde(c.reglaFuerte),
      disabledBorder: borde(c.regla),
      focusedBorder: borde(c.morado, 2),
      errorBorder: borde(c.tinta, 2),
      focusedErrorBorder: borde(c.tinta, 2.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.hoja,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      height: 80,
      indicatorColor: c.moradoTenue,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => textos.bodySmall!.copyWith(
          fontSize: 12,
          color: s.contains(WidgetState.selected) ? c.tinta : c.tintaSuave,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? c.tinta : c.tintaSuave,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.hoja,
      indicatorColor: c.relleno,
      selectedIconTheme: IconThemeData(color: c.tinta),
      unselectedIconTheme: IconThemeData(color: c.tintaSuave),
      selectedLabelTextStyle: textos.bodySmall!.copyWith(
        color: c.tinta,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textos.bodySmall,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.grafito,
      contentTextStyle: textos.bodyMedium!.copyWith(color: c.sobreGrafito),
      actionTextColor: c.sobreGrafito,
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: esquina),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.hoja,
      surfaceTintColor: const Color(0x00000000),
      showDragHandle: true,
      dragHandleColor: c.reglaFuerte,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radios.hoja)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.hoja,
      surfaceTintColor: const Color(0x00000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.hoja),
      ),
      titleTextStyle: textos.titleLarge,
      contentTextStyle: textos.bodyMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.sobreMorado : c.tintaSuave,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.morado : c.relleno,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.reglaFuerte),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.morado,
      linearTrackColor: c.regla,
      circularTrackColor: c.regla,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.grafito, borderRadius: esquina),
      textStyle: textos.bodySmall!.copyWith(color: c.sobreGrafito),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.tintaSuave,
      textColor: c.tinta,
      titleTextStyle: textos.titleMedium,
      subtitleTextStyle: textos.bodySmall,
    ),
  );
}
