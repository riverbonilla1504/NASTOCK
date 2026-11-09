---
description: "Tareas de HU-084 · Gestor de tiempo real en la app"
---

# Tareas: HU-084 · Gestor de tiempo real en la app

**Entrada**: [plan.md](plan.md), [spec.md](spec.md).

Una sola historia de usuario (US1). Solo app y E2E de la app: sin migraciones. Cada fase es una capa con sus pruebas y termina en un commit.

## Fase 1 · Núcleo de `lib/core/realtime/` (commit 1)

- [x] T001 [P] [US1] `canales.dart`: `Canales` y `canalesDeRol(rol, idUsuario)` (todos `mercado`, `fondo`, `usuario:{id}`; Analista + `supervision`; Administrador + `supervision` y `admin`); `test/core/realtime/canales_test.dart` (CA-1)
- [x] T002 [P] [US1] `evento_de_tiempo_real.dart`: `EventoDeTiempoReal` y `EventoDeEntidad` (tabla, id, versión; nunca montos)
- [x] T003 [P] [US1] `estado_conexion.dart`: `EstadoConexion`, `SenalDeConexion` y `ControlDeConexion` (conectado, reconectando, sinConexion); `test/core/realtime/estado_conexion_test.dart` (CA-3, CB-66)
- [x] T004 [US1] `fuente_de_tiempo_real.dart` (interfaz y `FuenteSupabaseDeTiempoReal` con canales privados) y `gestor_de_tiempo_real.dart` (abre canales, reparte eventos, avisa reconexiones y vuelta a primer plano, cierra); `test/core/realtime/gestor_de_tiempo_real_test.dart` y `falsos.dart` (CA-1, CA-3)
- [x] T005 [US1] `reloj.dart`: `RelojCorregido`, `calcularDesfase`, `relojProvider` (mide al iniciar sesión y al reconectar, conserva el desfase si falla); `test/core/realtime/reloj_test.dart` (CA-5, CB-70)

## Fase 2 · Foto y eventos (commit 2)

- [x] T006 [US1] `foto_y_eventos.dart`: `FotoYEventosNotifier<T>` (foto al montar, descarte por versión, registro nuevo por la API, quitar lo que ya no existe, foto completa al reconectar); `test/core/realtime/foto_y_eventos_test.dart` (CA-2, CA-3, CA-6)

## Fase 3 · Providers y ciclo de vida (commit 3)

- [x] T007 [US1] `tiempo_real_provider.dart`: `SuscripcionesDeRol`, `gestorDeTiempoRealProvider`, `conexionProvider`, `decisionesHabilitadasProvider`; `activador_de_tiempo_real.dart`; `test/core/realtime/tiempo_real_provider_test.dart` (CA-1, CA-4)

## Fase 4 · Barra de conexión e integración (commits 4 y 5)

- [x] T008 [P] [US1] `lib/shared/widgets/barra_de_conexion.dart`: `ContenidoConConexion` con "Reconectando…" y datos atenuados, y "Sin conexión"; `test/shared/widgets/barra_de_conexion_test.dart` (CA-3, CA-4)
- [x] T009 [US1] `lib/app/aplicacion.dart` (`ActivadorDeTiempoReal` en `builder`) y `lib/app/cascaron_de_navegacion.dart` (la barra sobre el contenido); pruebas de la app aisladas del socket real con `tiempoRealEnMemoria`; `test/app/cascaron_de_navegacion_test.dart` (CA-3, CA-4)

## Fase 5 · E2E y documentación (commit 6)

- [x] T010 [US1] `integration_test/app_test.dart`: tras ingresar con cada rol, el gestor abre los canales de su rol, el servidor los acepta todos, la conexión queda en `conectado` y al cerrar sesión no hay gestor (CA-1)
- [x] T011 [P] [US1] `docs/17-mapa-de-modulos.md` M-13: rutas de la app y pruebas
- [x] T012 [US1] Verificación rápida (analyze y pruebas de la app; sin `verificar.sh` completo por decisión del 2026-11-08) y cuerpo del PR
