# Investigación: HU-011

Fecha: 2026-11-15. Issue #28 consultado en GitHub, abierto y asignado a yulbastidas.

## Autorización

**Decisión**: RPC autorizada con `private.rol_actual()`, no con el JWT. **Motivo**: docs/03 §4 y PM-51. **Alternativa descartada**: escritura de perfiles desde Flutter o autorización por claims antiguos.

## Cupos

**Decisión**: reutilizar `private.crear_cupo(usuario, 0)` al pasar a Usuario; devolver efectivo con `cierre_cupo` y cerrar al salir, sin posiciones ni órdenes vivas. **Motivo**: RN-54/RN-55; función y tipo de movimiento ya existen. **Alternativa descartada**: asignación inicial o actualización directa de saldos.

## Concurrencia

**Decisión**: coordinar la protección del último administrador y la transición del cupo con bloqueos transaccionales compatibles con las operaciones existentes. Revisar el orden de bloqueos en implementación y probarlo. **Motivo**: RN-50/RN-54 deben sostenerse con solicitudes simultáneas. **Alternativa descartada**: comprobación separada de la escritura.

## Sesión

**Decisión**: renovar token por el adaptador Auth al recibir `perfil_actualizado` de la cuenta actual. Los providers existentes reconstruyen acceso y canales al cambiar el rol. **Motivo**: docs/04 §8 y docs/09 §7; `SuscripcionesDeRol` ya compara id y rol por valor. **Alternativa descartada**: asignar el rol confiando en la carga del evento o esperar a la expiración.

## Alcance y entorno

La pantalla es HU-098 y RN-56 es HU-065. Supuestos aplicables de docs/01: S2 Flutter, S3 USD, S4 decenas de usuarios y S6 plan gratuito. No se necesita resolver una pregunta de negocio nueva para implementar esta historia.

Al revisar el entorno: Flutter 3.41.0 en caché, distinto al requerido; Docker sin motor activo; Supabase CLI/Deno no presentes en PATH. Resolver esas condiciones antes de acreditar pruebas completas. Git Bash necesita ejecutarse fuera del sandbox en esta estación.
