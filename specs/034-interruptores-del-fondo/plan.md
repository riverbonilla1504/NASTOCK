# Plan: HU-034 · Interruptores del fondo

Una migración (`20261110100000_interruptores_del_fondo.sql`): `private.cambiar_interruptor`, `public.reanudar(interruptor)` (Administrador, exige un aporte confirmado: `FONDO_SIN_CAPITAL`) y `public.activar_freno(interruptor, motivo)` (Analista y Administrador, motivo obligatorio; guarda `motivo_pausa`, `pausado_por`, `pausado_en`), auditoría `interruptor.encendido` / `interruptor.apagado` y trigger que publica `interruptor` en el canal `admin` sin datos.

Decisiones sin regla explícita en `docs/`: repetir el estado actual responde `ESTADO_INVALIDO`; al quedar ambos encendidos se limpia el motivo de la pausa. El freno con efectos sobre sugerencias y órdenes y el botón del Analista son de HU-039; reanudar solo con la conciliación en `ok`, de HU-040.
Pruebas: `16_interruptores_del_fondo_test.sql` (30).
