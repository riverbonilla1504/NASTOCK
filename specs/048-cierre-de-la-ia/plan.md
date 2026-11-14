# Plan: HU-048 · Pantalla Oportunidades con la explicación de cada evaluación

**Rama**: `demo-ia-oportunidades` (D-70, #171) y `048-cierre-de-la-ia` (D-72, #196) · **Módulos**: M-07, M-16 · **Fuentes**: `docs/07` §14 · `docs/03` §4.3.

- **RPC** (migración `20261108200002_oportunidades_y_trabajo_agente.sql`): `public.oportunidades(bolsillo)` devuelve las evaluaciones del último ciclo completado; el Analista y el Administrador ven todos los bolsillos y el Usuario solo Usuarios (CA-2).
- **App** (`lib/features/oportunidades/`): `domain/oportunidad.dart` (resultado, nivel y lo que respondió JEV), `data/oportunidades_repositorio.dart`, `presentation/pagina_oportunidades.dart` (selector de bolsillo, tarjetas con chip de nivel, puntaje, confianza y probabilidades de JEV; excluidas aparte) y `detalle_de_oportunidad.dart` (por qué, qué la frena, lo que respondió JEV, aportes, datos del mercado y advertencias).

Decisiones sin regla explícita en `docs/`:
- La pantalla se refresca sola cada minuto y al deslizar; todavía no escucha el evento `ciclo_agente` (CA-5 queda pendiente).
- Sin titulares ni contexto (D-59).

Pruebas: `flutter test test/features/oportunidades` (8) · pgTAP `11_agente_y_oportunidades_test.sql` (CA-2) · E2E-06 (backend).
