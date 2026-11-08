/// Todos los componentes del sistema, por secciones. Datos de ejemplo.
library;

import 'package:flutter/material.dart';

import '../../core/errores/traduccion_de_errores.dart';
import '../../shared/widgets/avisos.dart';
import '../../shared/widgets/barra_superior.dart';
import '../../shared/widgets/botones.dart';
import '../../shared/widgets/calendario.dart';
import '../../shared/widgets/campo.dart';
import '../../shared/widgets/chip_de_estado.dart';
import '../../shared/widgets/cifras.dart';
import '../../shared/widgets/dialogo_de_confirmacion.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/forma_de_linea.dart';
import '../../shared/widgets/franja_de_la_jornada.dart';
import '../../shared/widgets/grafica_de_linea.dart';
import '../../shared/widgets/mensaje_de_error.dart';
import '../../shared/widgets/opciones_excluyentes.dart';
import '../../shared/widgets/tarjeta.dart';
import '../../shared/widgets/tarjeta_de_cotizacion.dart';
import '../tema.dart';
import 'datos_de_ejemplo.dart';
import 'pagina_catalogo.dart';

class PaginaComponentes extends StatefulWidget {
  const PaginaComponentes({super.key});

  @override
  State<PaginaComponentes> createState() => _PaginaComponentesState();
}

class _PaginaComponentesState extends State<PaginaComponentes> {
  static final DateTime _hoy = DateTime(2026, 11, 6);
  static final Set<DateTime> _festivos = {DateTime(2026, 11, 26)};
  static final Set<DateTime> _medias = {DateTime(2026, 11, 27)};

  DateTime _mes = DateTime(2026, 11);
  DateTimeRange? _periodo = DateTimeRange(
    start: DateTime(2026, 11, 9),
    end: DateTime(2026, 11, 20),
  );
  bool _enviando = false;
  String _rol = 'usuario';
  final TextEditingController _fueraDeRango = TextEditingController(
    text: '900',
  );

  @override
  void dispose() {
    _fueraDeRango.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const BarraSuperior(
        titulo: 'Componentes',
        acciones: [InterruptorDeTema()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacio.x4,
          Espacio.x2,
          Espacio.x4,
          Espacio.x8 * 2,
        ),
        children: [
          _Seccion(
            titulo: 'Color',
            children: [
              Wrap(
                spacing: Espacio.x2,
                runSpacing: Espacio.x2,
                children: [
                  _Muestra('Grafito', c.grafito),
                  _Muestra('Tinta', c.tinta),
                  _Muestra('Tinta suave', c.tintaSuave),
                  _Muestra('Tinta tenue', c.tintaTenue),
                  _Muestra('Papel', c.papel),
                  _Muestra('Hoja', c.hoja),
                  _Muestra('Morado', c.morado),
                  _Muestra('Morado tenue', c.moradoTenue),
                  _Muestra('Alza', c.alza),
                  _Muestra('Baja', c.baja),
                ],
              ),
            ],
          ),
          _Seccion(
            titulo: 'Tipografía',
            children: [
              Text('Mercado', style: textos.headlineMedium),
              Text('Jornada de hoy · viernes 6 nov', style: textos.titleLarge),
              Text('USD 10.000,00', style: textos.displaySmall),
              Text('Disponible en tu cupo', style: textos.titleMedium),
              Text('No tienes disponible suficiente.', style: textos.bodyLarge),
              Text('EN VIVO · HORA DE BOGOTÁ', style: textos.labelMedium),
            ],
          ),
          _Seccion(
            titulo: 'Botones',
            children: [
              Wrap(
                spacing: Espacio.x2,
                runSpacing: Espacio.x2,
                children: [
                  BotonPrimario(
                    texto: 'Nueva orden',
                    icono: Icons.add,
                    enviando: _enviando,
                    alPresionar: () async {
                      setState(() => _enviando = true);
                      await Future<void>.delayed(const Duration(seconds: 2));
                      if (mounted) setState(() => _enviando = false);
                    },
                  ),
                  BotonSecundario(texto: 'Cancelar', alPresionar: () {}),
                  BotonTexto(texto: 'Ver detalle', alPresionar: () {}),
                  const BotonPrimario(texto: 'Comprar', alPresionar: null),
                  const BotonSecundario(texto: 'Vender', alPresionar: null),
                ],
              ),
              const SizedBox(height: Espacio.x3),
              Align(
                alignment: Alignment.centerLeft,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva orden'),
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Campos',
            children: [
              const Campo(
                etiqueta: 'Monto (USD)',
                pista: 'USD 0,00',
                teclado: TextInputType.number,
                ayuda: 'Disponible en tu cupo: USD 1.240,00',
              ),
              const SizedBox(height: Espacio.x3),
              const _CampoConFoco(),
              const SizedBox(height: Espacio.x3),
              Campo(
                etiqueta: 'Antigüedad máxima de una cotización (s)',
                controlador: _fueraDeRango,
                teclado: TextInputType.number,
                error: 'El valor está fuera del rango permitido (15–600).',
              ),
              const SizedBox(height: Espacio.x3),
              const Campo(etiqueta: 'Contraseña', oculto: true),
              const SizedBox(height: Espacio.x3),
              CampoDePeriodo(
                etiqueta: 'Periodo',
                hoy: _hoy,
                periodo: _periodo,
                festivos: _festivos,
                mediasJornadas: _medias,
                ayuda: 'Hora de Bogotá. Según el calendario del broker.',
                alCambiar: (p) => setState(() => _periodo = p),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Avisos',
            children: [
              const AvisoEnLinea(
                tipo: TipoAviso.informacion,
                titulo: 'El mercado está cerrado',
                mensaje: 'Abre a las 09:30, hora de Bogotá.',
              ),
              const SizedBox(height: Espacio.x3),
              const AvisoEnLinea(
                tipo: TipoAviso.exito,
                titulo: 'Orden enviada al broker',
                mensaje: 'Su estado se actualiza en esta pantalla.',
              ),
              const SizedBox(height: Espacio.x3),
              const AvisoEnLinea(
                tipo: TipoAviso.advertencia,
                titulo: 'Fuera de la ventana de compras',
                mensaje:
                    'No se abren compras tan cerca de la apertura o del '
                    'cierre.',
              ),
              const SizedBox(height: Espacio.x3),
              AvisoEnLinea(
                tipo: TipoAviso.error,
                titulo: 'No se pudo crear la orden',
                mensaje: 'No tienes disponible suficiente.',
                accion: 'Revisar',
                alAccionar: () {},
              ),
              const SizedBox(height: Espacio.x3),
              const AvisoEnLinea(
                tipo: TipoAviso.desactualizado,
                titulo: 'Dato desactualizado',
                mensaje:
                    'El precio no está actualizado. Intenta en unos '
                    'segundos.',
              ),
              const SizedBox(height: Espacio.x3),
              const MensajeDeError(
                error: ErrorDeNegocio('FONDOS_INSUFICIENTES'),
              ),
              const SizedBox(height: Espacio.x3),
              Align(
                alignment: Alignment.centerLeft,
                child: BotonSecundario(
                  texto: 'Mostrar aviso temporal',
                  alPresionar: () => mostrarAvisoTemporal(
                    context,
                    'Parámetro guardado',
                    accion: 'Ver',
                    alAccionar: () {},
                  ),
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Opciones excluyentes',
            children: [
              OpcionesExcluyentes<String>(
                etiqueta: 'Rol',
                ayuda: 'Define qué verá la persona.',
                opciones: const [
                  OpcionExcluyente(valor: 'usuario', etiqueta: 'Usuario'),
                  OpcionExcluyente(valor: 'analista', etiqueta: 'Analista'),
                  OpcionExcluyente(
                    valor: 'administrador',
                    etiqueta: 'Administrador',
                  ),
                ],
                valor: _rol,
                alElegir: (rol) => setState(() => _rol = rol),
              ),
              const SizedBox(height: Espacio.x4),
              const OpcionesExcluyentes<String>(
                etiqueta: 'Rol (deshabilitado)',
                opciones: [
                  OpcionExcluyente(valor: 'usuario', etiqueta: 'Usuario'),
                  OpcionExcluyente(valor: 'analista', etiqueta: 'Analista'),
                ],
                valor: 'usuario',
                alElegir: null,
              ),
            ],
          ),
          const _Seccion(
            titulo: 'Chips de estado',
            children: [
              Wrap(
                spacing: Espacio.x2,
                runSpacing: Espacio.x2,
                children: [
                  ChipDeEstado.enVivo(),
                  ChipDeEstado.pendiente(),
                  ChipDeEstado.desactualizado(),
                  ChipDeEstado.deshabilitado(),
                  ChipDeEstado(
                    etiqueta: 'Abierto · hoy',
                    forma: FormaDeLinea.solida,
                    destacado: true,
                  ),
                ],
              ),
            ],
          ),
          const _Seccion(
            titulo: 'Cifras',
            children: [
              CifraUsd(10000, tamano: TamanoCifra.grande),
              SizedBox(height: Espacio.x2),
              Wrap(
                spacing: Espacio.x4,
                runSpacing: Espacio.x2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CifraUsd(512.36),
                  CifraUsd(231.08, desactualizada: true),
                  Variacion(2.47),
                  Variacion(-0.82),
                  Variacion(0),
                  AntiguedadDelDato(Duration(seconds: 8)),
                  AntiguedadDelDato(Duration(minutes: 2), desactualizado: true),
                ],
              ),
            ],
          ),
          _Seccion(
            titulo: 'Gráfica',
            children: [
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QLD frente a QQQ', style: textos.titleMedium),
                    const SizedBox(height: Espacio.x3),
                    GraficaDeLinea(
                      serie: _variacionDesdeApertura(Ejemplo.curvaQld),
                      referencia: _variacionDesdeApertura(Ejemplo.curvaQqq),
                      ahora: Ejemplo.fraccionAhora,
                      alto: 140,
                      rejilla: 4,
                      descripcion:
                          'QLD sube 2,47 % y QQQ sube 1,24 % desde la '
                          'apertura',
                    ),
                    const SizedBox(height: Espacio.x2),
                    Wrap(
                      spacing: Espacio.x4,
                      children: [
                        _Serie('QLD · ×2', c.morado, discontinua: false),
                        _Serie('QQQ · ×1', c.tintaTenue, discontinua: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Cotización',
            children: [
              TarjetaDeCotizacion(
                simbolo: 'AAPL',
                nombre: 'Apple',
                precio: 231.08,
                variacion: -0.82,
                antiguedad: const Duration(minutes: 2),
                desactualizado: true,
                acciones: [
                  const BotonPrimario(texto: 'Comprar', alPresionar: null),
                  BotonSecundario(texto: 'Vender', alPresionar: () {}),
                ],
              ),
            ],
          ),
          _Seccion(
            titulo: 'Franja de la jornada',
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: context.profundidad.degradadoGrafito,
                  borderRadius: BorderRadius.circular(Radios.control),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Espacio.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _RotuloSobreGrafito('Abierta · ahora 11:46'),
                      FranjaDeLaJornada(
                        apertura: Ejemplo.apertura,
                        cierre: Ejemplo.cierre,
                        ahora: Ejemplo.ahora,
                      ),
                      const SizedBox(height: Espacio.x4),
                      const _RotuloSobreGrafito(
                        'Media jornada · cierra a las 13:00',
                      ),
                      FranjaDeLaJornada(
                        apertura: Ejemplo.apertura,
                        cierre: Ejemplo.cierreMediaJornada,
                        ahora: Ejemplo.ahora,
                      ),
                      const SizedBox(height: Espacio.x4),
                      const _RotuloSobreGrafito('Cerrada · después del cierre'),
                      FranjaDeLaJornada(
                        apertura: Ejemplo.apertura,
                        cierre: Ejemplo.cierre,
                        ahora: Ejemplo.despuesDelCierre,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Confirmación',
            children: [
              BotonSecundario(
                texto: 'Abrir la confirmación',
                alPresionar: () => confirmarAccion(
                  context,
                  titulo: 'Confirmar compra',
                  detalle: 'Compra a mercado',
                  simbolo: 'QLD',
                  monto: 250,
                  textoConfirmar: 'Comprar',
                  alConfirmar: () =>
                      Future<void>.delayed(const Duration(milliseconds: 800)),
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Calendario',
            children: [
              Tarjeta(
                child: CalendarioDelMercado(
                  mes: _mes,
                  hoy: _hoy,
                  festivos: _festivos,
                  mediasJornadas: _medias,
                  seleccion: _periodo,
                  alCambiarMes: (m) => setState(() => _mes = m),
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Estados',
            children: [
              Tarjeta(
                child: EstadoVacio(
                  titulo: 'Aún no tienes posiciones',
                  mensaje:
                      'Cuando compres, aparecen aquí con su resultado en '
                      'vivo.',
                  accion: BotonSecundario(
                    texto: 'Nueva orden',
                    alPresionar: () {},
                  ),
                ),
              ),
              const SizedBox(height: Espacio.x3),
              const Tarjeta(child: EstadoCargando()),
              const SizedBox(height: Espacio.x3),
              EstadoDeError(
                error: const ErrorDeNegocio('INTEGRACION_CAIDA'),
                alReintentar: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<double> _variacionDesdeApertura(List<double> precios) => [
    for (final p in precios) (p / precios.first - 1) * 100,
  ];
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(top: Espacio.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.tinta, width: 2)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: Espacio.x2,
                bottom: Espacio.x3,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra(this.nombre, this.color);

  final String nombre;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: c.hoja,
        border: Border.all(color: c.regla),
        borderRadius: BorderRadius.circular(Radios.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 40, color: color),
          Padding(
            padding: const EdgeInsets.all(Espacio.x2),
            child: Text(nombre, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Serie extends StatelessWidget {
  const _Serie(this.nombre, this.color, {required this.discontinua});

  final String nombre;
  final Color color;
  final bool discontinua;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrazoDeLinea(
          forma: discontinua ? FormaDeLinea.discontinua : FormaDeLinea.solida,
          color: color,
        ),
        const SizedBox(width: Espacio.x2),
        Text(nombre, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Campo en su estado de foco, para verlo sin abrir el teclado.
class _CampoConFoco extends StatelessWidget {
  const _CampoConFoco();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaDeCampo('Monto (USD), con foco'),
        const SizedBox(height: Espacio.x1 + 2),
        InputDecorator(
          isFocused: true,
          decoration: const InputDecoration(),
          child: Text('USD 250,00', style: textos.bodyLarge),
        ),
      ],
    );
  }
}

/// Rótulo sobre grafito para los estados de la franja.
class _RotuloSobreGrafito extends StatelessWidget {
  const _RotuloSobreGrafito(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.x1),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(color: c.sobreGrafitoSuave),
      ),
    );
  }
}
