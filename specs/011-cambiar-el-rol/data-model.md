# Modelo de datos: HU-011

No se agregan tablas ni tipos. Fuentes: docs/06 §4 y §5.1.

| Entidad | Uso |
|---|---|
| perfiles | Autorizar actor y actualizar rol destino conservando identidad/estado. |
| subcuentas | Crear cupo en cero o cerrar y devolver efectivo a usuarios_comun. |
| posiciones y ordenes | Rechazar cierre mientras existan posiciones no cerradas u órdenes vivas. |
| movimientos y asientos | Registrar cierre_cupo mediante doble partida. |
| Bitácora | Registrar cuenta.rol_cambiado con actor y cuenta afectada. |

## Transiciones

- Analista/Administrador → Usuario: nuevo cupo en cero.
- Usuario → otro rol: exigir ausencia de posiciones/órdenes vivas, devolver efectivo y cerrar cupo.
- Analista ↔ Administrador: proteger último administrador y acción propia.

Perfil, libro, auditoría y publicación se confirman o revierten juntos. El evento privado usa la carga mínima de docs/09 §4, sin montos ni datos personales.
