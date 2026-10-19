# FR-009 · Prueba de humo tras cada despliegue

| Campo | Valor |
|---|---|
| Identificador | FR-009 |
| Nombre | Prueba de humo tras cada despliegue |
| Épica | [E-01 · Cimientos y calidad continua](../E-01-cimientos-y-calidad-continua/README.md) |

## Rol o actor

Flujo de despliegue (GitHub Actions)

## Descripción

Después de cada despliegue, el sistema debe comprobar: respuesta de `ping()`, estado del mercado con calendario de los próximos 10 días, entorno `mvp` sin proveedores simulados, ingreso permitido solo con Google, acceso de lectura a la cuenta paper, ninguna integración caída y exactamente una configuración de decisión y un prompt de contexto activos.

## Fuente

15 §11 · CB-91 · CB-92

## Historias que lo implementan

- [TT-08 · Despliegue continuo al proyecto MVP con prueba de humo](../E-01-cimientos-y-calidad-continua/TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) (R1)
- [HU-114 · Lista de verificación antes de abrir el MVP al equipo](../E-12-seguridad-auditoria-y-cumplimiento/HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) (R6)
