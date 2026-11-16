# Plan de implementación · HU-032

Rama: `032-aviso-dato-desactualizado`. Base: `d369180`.
Estado: implementación inicial; verificación completa pendiente.

## Contexto y constitución
Flutter/Riverpod, Supabase/Postgres. M-05 y punto de consumo M-10.
Se conservan RR-11, las políticas RLS y las escrituras por RPC.
El parámetro ya existe desde HU-033 (60 s, rango 15–600): no duplicarlo.
La IA no ejecuta operaciones. No cambian permisos ni servicios.

## Investigación y decisiones
La app usaba recibido_en para mostrar antigüedad y sustituía momento por la
hora del lote. El motor de políticas usa cotizaciones.momento. Se agrega m,
hora original por símbolo, al evento; recibido_en conserva la hora del lote.
No se considera fresca una cotización sin parámetro verificado ni un símbolo
sin cotización. Los eventos antiguos no reemplazan precios más nuevos.

## Capas
1. Migración hacia adelante: conservar la función actual y agregar m al payload.
2. Provider: leer el límite, refrescar por reconexión/evento admin y cada minuto
   para los usuarios sin acceso al canal admin; evaluar por símbolo cada segundo.
3. Pantalla: reutilizar CifraUsd y FilaDeCotizacion; aviso en el precio seleccionado.
4. Orden: bloquear Comprar, Revisar y Confirmar; revalidar antes de la RPC.
   Ventas conservan su comportamiento y el servidor vuelve a validar.
5. Pruebas: límite exacto, reloj controlado sin eventos, congelación, recuperación
   por símbolo y contrato de timestamps de Postgres.

## Diseño de la interfaz
Se reutilizan tokens y componentes de DESIGN.md, sin pantalla ni navegación nueva.
El aviso acompaña a la cifra y no depende solo del color. La revisión visual
en Chrome y Android está pendiente.

## Validación
Dart format ejecutado. Pruebas Flutter, pgTAP y E2E pendientes.
El SDK disponible es Dart 3.13.5; pubspec exige ^3.13.7.
No integrar ni cerrar #51 hasta pasar scripts/verificar.sh completo.
