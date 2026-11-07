/// Tokens y tema de la app: dirección "Almanaque" en grises (D-67).
///
/// Lo visual lo gobierna `DESIGN.md`. La interfaz es gris y el color solo
/// lleva datos: morado para las líneas de gráfica, la marca de "ahora", hoy y
/// el foco; verde y rojo apagados solo para la dirección de un precio.
/// Ninguna pantalla define colores, tamaños ni fuentes sueltos: usa estos
/// tokens y los componentes de `lib/shared/widgets/` (docs/15 §12).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// Familias tipográficas empaquetadas (`assets/fonts/archivo/`).
abstract final class Familias {
  /// Archivo de ancho normal: texto, cifras y controles.
  static const String texto = 'Archivo';

  /// Archivo condensada: títulos y rótulos.
  static const String condensada = 'ArchivoCondensado';
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
  /// Controles, tarjetas y avisos.
  static const double control = 4;

  /// Botón flotante, hojas y diálogos.
  static const double hoja = 8;
}

/// Duraciones del movimiento: solo cambian estados.
abstract final class Duracion {
  static const Duration estado = Duration(milliseconds: 150);
  static const Duration transicion = Duration(milliseconds: 200);
}

/// Cifras tabulares: las columnas de dinero se alinean.
const List<FontFeature> cifrasTabulares = [FontFeature.tabularFigures()];

/// Colores con nombre del Almanaque, en claro y en oscuro.
@immutable
class ColoresAlmanaque extends ThemeExtension<ColoresAlmanaque> {
  const ColoresAlmanaque({
    required this.grafito,
    required this.sobreGrafito,
    required this.sobreGrafitoSuave,
    required this.moradoSobreGrafito,
    required this.tinta,
    required this.tintaSuave,
    required this.tintaTenue,
    required this.papel,
    required this.hoja,
    required this.regla,
    required this.reglaFuerte,
    required this.morado,
    required this.moradoTenue,
    required this.sobreMorado,
    required this.alza,
    required this.baja,
  });

  /// Barra superior y aviso temporal.
  final Color grafito;

  /// Texto sobre grafito.
  final Color sobreGrafito;

  /// Texto secundario sobre grafito.
  final Color sobreGrafitoSuave;

  /// Aguja de "ahora" sobre grafito.
  final Color moradoSobreGrafito;

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

  /// Líneas de gráfica, hoy y foco.
  final Color morado;

  /// Fondo de lo seleccionado.
  final Color moradoTenue;

  /// Texto sobre morado.
  final Color sobreMorado;

  /// Variación al alza (siempre con flecha y signo).
  final Color alza;

  /// Variación a la baja (siempre con flecha y signo).
  final Color baja;

  static const ColoresAlmanaque claro = ColoresAlmanaque(
    grafito: Color(0xFF27272A),
    sobreGrafito: Color(0xFFF4F4F5),
    sobreGrafitoSuave: Color(0xFFB4B4BC),
    moradoSobreGrafito: Color(0xFFC2B3FF),
    tinta: Color(0xFF18181B),
    tintaSuave: Color(0xFF52525B),
    tintaTenue: Color(0xFF6B6B74),
    papel: Color(0xFFF2F2F3),
    hoja: Color(0xFFFFFFFF),
    regla: Color(0x1F18181B),
    reglaFuerte: Color(0x4D18181B),
    morado: Color(0xFF6A45E0),
    moradoTenue: Color(0xFFECE8FD),
    sobreMorado: Color(0xFFFFFFFF),
    alza: Color(0xFF2D6A4F),
    baja: Color(0xFFA3383C),
  );

  static const ColoresAlmanaque oscuro = ColoresAlmanaque(
    grafito: Color(0xFF26262A),
    sobreGrafito: Color(0xFFF4F4F5),
    sobreGrafitoSuave: Color(0xFFA9A9B2),
    moradoSobreGrafito: Color(0xFFC2B3FF),
    tinta: Color(0xFFEDEDEF),
    tintaSuave: Color(0xFFA1A1AA),
    tintaTenue: Color(0xFF8B8B94),
    papel: Color(0xFF111113),
    hoja: Color(0xFF1C1C1F),
    regla: Color(0x1FEDEDEF),
    reglaFuerte: Color(0x4DEDEDEF),
    morado: Color(0xFFB3A1FF),
    moradoTenue: Color(0xFF2E2850),
    sobreMorado: Color(0xFF18181B),
    alza: Color(0xFF7FC9A0),
    baja: Color(0xFFF0908F),
  );

  @override
  ColoresAlmanaque copyWith({
    Color? grafito,
    Color? sobreGrafito,
    Color? sobreGrafitoSuave,
    Color? moradoSobreGrafito,
    Color? tinta,
    Color? tintaSuave,
    Color? tintaTenue,
    Color? papel,
    Color? hoja,
    Color? regla,
    Color? reglaFuerte,
    Color? morado,
    Color? moradoTenue,
    Color? sobreMorado,
    Color? alza,
    Color? baja,
  }) {
    return ColoresAlmanaque(
      grafito: grafito ?? this.grafito,
      sobreGrafito: sobreGrafito ?? this.sobreGrafito,
      sobreGrafitoSuave: sobreGrafitoSuave ?? this.sobreGrafitoSuave,
      moradoSobreGrafito: moradoSobreGrafito ?? this.moradoSobreGrafito,
      tinta: tinta ?? this.tinta,
      tintaSuave: tintaSuave ?? this.tintaSuave,
      tintaTenue: tintaTenue ?? this.tintaTenue,
      papel: papel ?? this.papel,
      hoja: hoja ?? this.hoja,
      regla: regla ?? this.regla,
      reglaFuerte: reglaFuerte ?? this.reglaFuerte,
      morado: morado ?? this.morado,
      moradoTenue: moradoTenue ?? this.moradoTenue,
      sobreMorado: sobreMorado ?? this.sobreMorado,
      alza: alza ?? this.alza,
      baja: baja ?? this.baja,
    );
  }

  @override
  ColoresAlmanaque lerp(ThemeExtension<ColoresAlmanaque>? other, double t) {
    if (other is! ColoresAlmanaque) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresAlmanaque(
      grafito: m(grafito, other.grafito),
      sobreGrafito: m(sobreGrafito, other.sobreGrafito),
      sobreGrafitoSuave: m(sobreGrafitoSuave, other.sobreGrafitoSuave),
      moradoSobreGrafito: m(moradoSobreGrafito, other.moradoSobreGrafito),
      tinta: m(tinta, other.tinta),
      tintaSuave: m(tintaSuave, other.tintaSuave),
      tintaTenue: m(tintaTenue, other.tintaTenue),
      papel: m(papel, other.papel),
      hoja: m(hoja, other.hoja),
      regla: m(regla, other.regla),
      reglaFuerte: m(reglaFuerte, other.reglaFuerte),
      morado: m(morado, other.morado),
      moradoTenue: m(moradoTenue, other.moradoTenue),
      sobreMorado: m(sobreMorado, other.sobreMorado),
      alza: m(alza, other.alza),
      baja: m(baja, other.baja),
    );
  }
}

/// Profundidad del Almanaque: sombras suaves, el degradado gris de la barra
/// superior y el velo traslúcido de lo que flota sobre el contenido.
///
/// Los degradados y difuminados son grises. El único degradado de color es el
/// área morada bajo la línea de una gráfica, porque es dato (DESIGN.md).
@immutable
class ProfundidadAlmanaque extends ThemeExtension<ProfundidadAlmanaque> {
  const ProfundidadAlmanaque({
    required this.sombraTarjeta,
    required this.sombraFlotante,
    required this.sombraHoja,
    required this.degradadoGrafito,
    required this.velo,
    required this.veloGrafito,
  });

  /// Desenfoque detrás de la barra de pestañas, el aviso temporal y las hojas.
  static const double desenfoque = 18;

  /// Tarjetas: una sombra corta y otra amplia, siempre desplazadas hacia abajo.
  final List<BoxShadow> sombraTarjeta;

  /// Botón flotante y aviso temporal.
  final List<BoxShadow> sombraFlotante;

  /// Hojas inferiores.
  final List<BoxShadow> sombraHoja;

  /// Barra superior: grafito un poco más claro arriba.
  final LinearGradient degradadoGrafito;

  /// Hoja traslúcida para superficies con desenfoque.
  final Color velo;

  /// Grafito traslúcido para el aviso temporal.
  final Color veloGrafito;

  static const ProfundidadAlmanaque claro = ProfundidadAlmanaque(
    sombraTarjeta: [
      BoxShadow(color: Color(0x0F18181B), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0D18181B), offset: Offset(0, 6), blurRadius: 16),
    ],
    sombraFlotante: [
      BoxShadow(color: Color(0x1F18181B), offset: Offset(0, 2), blurRadius: 4),
      BoxShadow(
        color: Color(0x2418181B),
        offset: Offset(0, 10),
        blurRadius: 24,
      ),
    ],
    sombraHoja: [
      BoxShadow(
        color: Color(0x2418181B),
        offset: Offset(0, -4),
        blurRadius: 28,
      ),
    ],
    degradadoGrafito: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF35353A), Color(0xFF232326)],
    ),
    velo: Color(0xE6FFFFFF),
    veloGrafito: Color(0xE027272A),
  );

  static const ProfundidadAlmanaque oscuro = ProfundidadAlmanaque(
    sombraTarjeta: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 8), blurRadius: 20),
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
    degradadoGrafito: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF303035), Color(0xFF1E1E22)],
    ),
    velo: Color(0xE01C1C1F),
    veloGrafito: Color(0xEB3A3A40),
  );

  @override
  ProfundidadAlmanaque copyWith({
    List<BoxShadow>? sombraTarjeta,
    List<BoxShadow>? sombraFlotante,
    List<BoxShadow>? sombraHoja,
    LinearGradient? degradadoGrafito,
    Color? velo,
    Color? veloGrafito,
  }) {
    return ProfundidadAlmanaque(
      sombraTarjeta: sombraTarjeta ?? this.sombraTarjeta,
      sombraFlotante: sombraFlotante ?? this.sombraFlotante,
      sombraHoja: sombraHoja ?? this.sombraHoja,
      degradadoGrafito: degradadoGrafito ?? this.degradadoGrafito,
      velo: velo ?? this.velo,
      veloGrafito: veloGrafito ?? this.veloGrafito,
    );
  }

  @override
  ProfundidadAlmanaque lerp(
    ThemeExtension<ProfundidadAlmanaque>? other,
    double t,
  ) {
    if (other is! ProfundidadAlmanaque) return this;
    return ProfundidadAlmanaque(
      sombraTarjeta: BoxShadow.lerpList(sombraTarjeta, other.sombraTarjeta, t)!,
      sombraFlotante: BoxShadow.lerpList(
        sombraFlotante,
        other.sombraFlotante,
        t,
      )!,
      sombraHoja: BoxShadow.lerpList(sombraHoja, other.sombraHoja, t)!,
      degradadoGrafito: LinearGradient.lerp(
        degradadoGrafito,
        other.degradadoGrafito,
        t,
      )!,
      velo: Color.lerp(velo, other.velo, t)!,
      veloGrafito: Color.lerp(veloGrafito, other.veloGrafito, t)!,
    );
  }
}

/// Atajos a los tokens del tema actual.
extension ColoresDelContexto on BuildContext {
  ColoresAlmanaque get colores =>
      Theme.of(this).extension<ColoresAlmanaque>() ?? ColoresAlmanaque.claro;

  ProfundidadAlmanaque get profundidad =>
      Theme.of(this).extension<ProfundidadAlmanaque>() ??
      ProfundidadAlmanaque.claro;
}

/// Tema claro (el de uso diurno, durante la jornada).
ThemeData crearTema() => _construir(
  ColoresAlmanaque.claro,
  ProfundidadAlmanaque.claro,
  Brightness.light,
);

/// Tema oscuro, con los mismos roles.
ThemeData crearTemaOscuro() => _construir(
  ColoresAlmanaque.oscuro,
  ProfundidadAlmanaque.oscuro,
  Brightness.dark,
);

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

TextTheme _textos(ColoresAlmanaque c) {
  const cond = Familias.condensada;
  return TextTheme(
    displayLarge: _estilo(
      44,
      FontWeight.w800,
      c.tinta,
      familia: cond,
      alto: 1.05,
    ),
    displayMedium: _estilo(
      36,
      FontWeight.w800,
      c.tinta,
      familia: cond,
      alto: 1.1,
    ),
    displaySmall: _estilo(30, FontWeight.w600, c.tinta, alto: 1.15),
    headlineLarge: _estilo(
      32,
      FontWeight.w800,
      c.tinta,
      familia: cond,
      alto: 1.1,
    ),
    headlineMedium: _estilo(
      28,
      FontWeight.w800,
      c.tinta,
      familia: cond,
      alto: 1.15,
    ),
    headlineSmall: _estilo(
      24,
      FontWeight.w800,
      c.tinta,
      familia: cond,
      alto: 1.2,
    ),
    titleLarge: _estilo(
      20,
      FontWeight.w700,
      c.tinta,
      familia: cond,
      alto: 1.25,
    ),
    titleMedium: _estilo(16, FontWeight.w600, c.tinta, alto: 1.35),
    titleSmall: _estilo(14, FontWeight.w600, c.tinta, alto: 1.35),
    bodyLarge: _estilo(16, FontWeight.w400, c.tinta, alto: 1.45),
    bodyMedium: _estilo(14, FontWeight.w400, c.tinta, alto: 1.45),
    bodySmall: _estilo(12, FontWeight.w400, c.tintaSuave, alto: 1.4),
    labelLarge: _estilo(15, FontWeight.w600, c.tinta, alto: 1.2),
    labelMedium: _estilo(
      12,
      FontWeight.w700,
      c.tintaSuave,
      familia: cond,
      alto: 1.2,
      espaciado: 0.6,
    ),
    labelSmall: _estilo(
      11,
      FontWeight.w700,
      c.tintaSuave,
      familia: cond,
      alto: 1.2,
      espaciado: 0.5,
    ),
  );
}

ThemeData _construir(
  ColoresAlmanaque c,
  ProfundidadAlmanaque p,
  Brightness brillo,
) {
  final textos = _textos(c);
  final esquina = BorderRadius.circular(Radios.control);
  OutlineInputBorder borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: esquina,
        borderSide: BorderSide(color: color, width: ancho),
      );
  const alturaBoton = Size(64, Espacio.objetivoTactil);
  const rellenoBoton = EdgeInsets.symmetric(horizontal: Espacio.x5);

  final esquema = ColorScheme(
    brightness: brillo,
    primary: c.tinta,
    onPrimary: c.papel,
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
    surfaceContainerHighest: c.papel,
    outline: c.reglaFuerte,
    outlineVariant: c.regla,
    inverseSurface: c.grafito,
    onInverseSurface: c.sobreGrafito,
    inversePrimary: c.moradoSobreGrafito,
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
      backgroundColor: c.grafito,
      foregroundColor: c.sobreGrafito,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: c.sobreGrafito),
      actionsIconTheme: IconThemeData(color: c.sobreGrafito),
      titleTextStyle: textos.headlineSmall!.copyWith(color: c.sobreGrafito),
    ),
    cardTheme: CardThemeData(
      color: c.hoja,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: esquina,
        side: BorderSide(color: c.regla),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.regla, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.tinta,
        foregroundColor: c.papel,
        disabledBackgroundColor: c.regla,
        disabledForegroundColor: c.tintaTenue,
        minimumSize: alturaBoton,
        padding: rellenoBoton,
        shape: RoundedRectangleBorder(borderRadius: esquina),
        textStyle: textos.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? c.tintaTenue : c.tinta,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.disabled) ? c.reglaFuerte : c.tinta,
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.tinta,
        disabledForegroundColor: c.tintaTenue,
        minimumSize: alturaBoton,
        padding: const EdgeInsets.symmetric(horizontal: Espacio.x3),
        shape: RoundedRectangleBorder(borderRadius: esquina),
        textStyle: textos.labelLarge!.copyWith(
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.tinta,
      foregroundColor: c.papel,
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
          color: s.contains(WidgetState.selected) ? c.tinta : c.tintaSuave,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
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
      indicatorColor: c.moradoTenue,
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
        (s) => s.contains(WidgetState.selected) ? c.hoja : c.tintaSuave,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.tinta : c.regla,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.reglaFuerte),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.tinta,
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
