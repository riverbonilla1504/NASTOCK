# Plan: HU-101 · Pantalla de parámetros e interruptores

**Rama**: `101-pantalla-de-parametros` (apilada sobre HU-034) · **Módulo**: M-08 / M-16 · Solo app, sin SQL.

`lib/features/admin/parametros/`: modelos (`Parametro`, `CambioDeParametro`, `Interruptores`), `ParametrosRepositorio` (lee `parametros`, `parametros_historial` y `fondos`; escribe por `actualizar_parametro`, `reanudar` y `activar_freno`), providers con foto y los eventos `parametro` e `interruptor` del canal `admin`, y `PaginaParametros` (vista de parámetros por tema con edición en hoja inferior —valor, motivo e historial— y vista de interruptores). El reparto se edita junto y exige sumar 100. Ruta `/admin/parametros` como subruta de Administración.
