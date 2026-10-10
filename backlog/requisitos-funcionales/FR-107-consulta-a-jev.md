# FR-107 · Consulta a JEV

| Campo | Valor |
|---|---|
| Identificador | FR-107 |
| Nombre | Consulta a JEV |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal) y JEV

## Descripción

El sistema debe hacer una llamada a JEV por candidata con todas las preguntas de la configuración activa, con la versión del modelo fijada, por TypeSafe o por Cloudflare según `JEV_PROVEEDOR`, y guardar el modelo que devuelve cada respuesta.

## Fuente

07 §5 · 07 §6.1 · D-43 · CB-89 · CB-90

## Historias que lo implementan

- [HU-045 · Adaptador de JEV y estado en etiquetas](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) (R3)
