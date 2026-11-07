# Archivo

Fuente de la app (HU-116, D-67, `DESIGN.md`).

- **Origen**: Archivo, de Omnibus-Type. Archivo variable `Archivo[wdth,wght].ttf` de
  `https://github.com/google/fonts/tree/main/ofl/archivo`, descargado el 2026-11-06.
- **Licencia**: SIL Open Font License 1.1, sin nombre reservado (`OFL.txt`).
- **Qué hay aquí**: siete instancias estáticas generadas con `fontTools`
  (`varLib.instancer`) y recortadas al latín (U+0020–U+024F, puntuación general,
  monedas, letras con forma, flechas, `−` y `×`), con todas sus funciones
  OpenType, entre ellas las cifras tabulares (`tnum`).

| Archivo | Familia en `pubspec.yaml` | Peso | Ancho |
|---|---|---|---|
| `Archivo-Regular.ttf` | Archivo | 400 | 100 |
| `Archivo-Medium.ttf` | Archivo | 500 | 100 |
| `Archivo-SemiBold.ttf` | Archivo | 600 | 100 |
| `Archivo-Bold.ttf` | Archivo | 700 | 100 |
| `ArchivoCondensado-SemiBold.ttf` | ArchivoCondensado | 600 | 78 |
| `ArchivoCondensado-Bold.ttf` | ArchivoCondensado | 700 | 78 |
| `ArchivoCondensado-ExtraBold.ttf` | ArchivoCondensado | 800 | 78 |

Se usan instancias estáticas y no la fuente variable porque Flutter no aplica de
forma fiable el eje de peso de una fuente variable con `fontWeight` en todas las
plataformas (`specs/116-tema-y-estilos-de-la-v2/research.md`, R-1).

Para regenerarlas: `instantiateVariableFont(fuente, {"wght": <peso>, "wdth": <ancho>})`
y después `fontTools.subset` con los rangos de arriba y `layout_features = ["*"]`.
