# Plan: HU-085 · Alertas por audiencia

**Rama**: `085-alertas-por-audiencia` · **Issue**: #109 · **Fecha**: 2026-11-15.

## Contexto técnico y constitución

Postgres/Supabase con RLS, funciones internas SQL y Flutter 3.47.9/Riverpod. Sin dependencias nuevas. Fuentes: docs/06 §5.5, docs/03 §4.3, docs/09 §3–4, docs/05 §11. FR-191/FR-065; CA-1 a CA-5 de spec.md. M-18/M-14 y las interfaces de M-05/M-13. Sin acceso de escritura por API ni secretos. Privacidad de alertas personales aprobada y documentada antes de implementar (historial 3.29). Supuestos S2/S4/S6 de docs/01. No hay preguntas pendientes que bloqueen esta historia.

## Investigación y diseño

La tabla aún no existe. `sincronizar_activos` ya desactiva símbolos no negociables: conectar un trigger SQL a ese cambio mantiene el aviso en la misma transacción sin duplicar el proveedor de calendario. Crear/resolver alertas solo desde `private`, con índice único parcial de clave activa y eventos de entidad en `supervision`. La audiencia se decide por el perfil activo, nunca por claims. Al resolver, liberar la clave permite rearmar. La app usa el patrón foto + eventos y permite recargar; no agrega notificaciones ni canales nuevos para Usuario (HU-086 fuera del MVP).

## Estructura y contrato

- `supabase/migrations/20261115130000_alertas_por_audiencia.sql`: tipos, tabla, RLS, funciones internas y trigger de activos.
- `supabase/tests/database/24_alertas_test.sql`: permisos, deduplicación, rearme y símbolo no negociable.
- `lib/features/alertas/`: dominio, repositorio de lectura y pantalla.
- `test/features/alertas/`: widget y estados de carga/error/vacío.
- `integration_test/app_test.dart`: la pestaña abre la pantalla real.

`private.crear_alerta` recibe tipo, audiencia, título, cuerpo y clave; opcionalmente destinatario, severidad, referencia y origen. Devuelve el id activo: repetir la clave no crea otra fila ni otro aviso. `private.resolver_alerta(clave)` resuelve la activa; repetir la resolución es inocuo. No se exponen como RPC públicas. La app solo lee por RLS.

## Diseño visual y validación

Reutilizar BarraSuperior, AvisoEnLinea, EstadoCargando/EstadoVacio/EstadoDeError y tokens de DESIGN.md. Lista de avisos activos, sin controles administrativos para resolverlos. Distinguir severidad con texto/forma además del color; 360 dp, texto ampliado y tema claro/oscuro. Verificar con widget, análisis, pgTAP y CI/E2E completos. Los comandos Impeccable no están conectados en esta sesión: se aplica su revisión de forma/auditoría/pulido al sistema existente sin introducir otro estilo.

## Dependencias

Primero contrato SQL y pruebas, después repositorio/proveedor/pantalla, luego E2E y catálogo/mapa. HU-086 genera notificaciones futuras; esta historia no la implementa. No marcar terminado sin CI y verificación completa.
