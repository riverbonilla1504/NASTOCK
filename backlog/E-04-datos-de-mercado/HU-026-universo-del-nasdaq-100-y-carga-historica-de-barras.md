# HU-026 · Universo del NASDAQ-100 y carga histórica de barras

| Campo | Valor |
|---|---|
| Épica | [E-04 · Datos de mercado](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-04` · `M-05` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que el sistema tenga la lista de los componentes del NASDAQ-100 y sus ETFs con dos años de historia,  
**para** que el mercado y la IA trabajen sobre un universo conocido y con datos suficientes.

## Requisitos funcionales

- [FR-061 · Universo de símbolos](../requisitos-funcionales/FR-061-universo-de-simbolos.md)
- [FR-062 · Carga histórica de barras](../requisitos-funcionales/FR-062-carga-historica-de-barras.md)

## Reglas

06 §5.2 · 10 §12 · 02 §1 · D-06 · Q-13

## Criterios de aceptación

- **CA-1** Dada la base recién creada, cuando se consulta `lista_blanca`, entonces Usuarios tiene QLD y QQQ, y Arriesgadas tiene TQQQ y los componentes del NASDAQ-100 con su nombre y su sector.
- **CA-2** Dada la carga inicial, cuando termina, entonces cada símbolo del universo tiene dos años de barras diarias en `barras_diarias`.
- **CA-3** Dado que la carga inicial corre otra vez, cuando termina, entonces no duplica barras.
- **CA-4** (permiso) Dada cualquier persona activa, cuando lee `lista_blanca` y `barras_diarias`, entonces las ve; y cuando intenta escribir directo, la base de datos lo rechaza.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tabla `lista_blanca` (06 §5.2) con RLS de lectura para todos y la semilla del universo con su sector.
- [ ] Migración: tablas `barras_diarias` y `barras_minuto` con RLS de lectura.
- [ ] Funciones: `_shared/mercado/` con la interfaz `snapshots` y `barras`, `alpaca.ts` y `simulado.ts` (barras históricas guardadas como datos de prueba y caminata determinista con semilla fija).
- [ ] Función `calendario-mercado`: carga inicial de dos años de barras diarias del universo.
- [ ] `seed.sql`: un año de barras diarias de prueba (15 §3).
- [ ] Pruebas `deno test` de los adaptadores con respuestas grabadas y del simulado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](../E-01-cimientos-y-calidad-continua/TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | Crea tablas y funciones sobre el proyecto base. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | El proveedor de mercado se elige con `_shared/proveedores.ts`. |
| Habilita | [HU-027 · Calendario, reloj y estado del mercado](HU-027-calendario-reloj-y-estado-del-mercado.md) | HU-027: sincroniza los atributos de los símbolos de la lista blanca. |
| Habilita | [HU-028 · Ingesta de precios cada 15 segundos](HU-028-ingesta-de-precios-cada-15-segundos.md) | HU-028: consulta los símbolos del universo. |
| Habilita | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | HU-029: guarda las barras de los símbolos del universo. |
| Habilita | [HU-036 · Editar la lista blanca](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md) | HU-036: edita la tabla `lista_blanca` sembrada con el universo. |
| Habilita | [HU-041 · Noticias de las candidatas](../E-06-ia-contexto-y-decision/HU-041-noticias-de-las-candidatas.md) | HU-041: descarga noticias de los símbolos del universo. |

## Notas técnicas

QQQ se ingiere siempre, aunque no esté activo en ningún bolsillo: es la referencia del índice. Alpaca no informa qué acciones componen el índice: la lista la mantiene el Administrador ([HU-036](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md)).

## Documentación a actualizar

Ninguna.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde
