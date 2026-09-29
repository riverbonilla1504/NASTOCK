#!/usr/bin/env python3
"""Verifica la consistencia de docs/ (la fuente de verdad del proyecto).

Comprueba que:
  1. Todo enlace relativo apunta a un archivo que existe y, si lleva ancla,
     a un encabezado que existe (con la misma regla de anclas de GitHub).
  2. Todo identificador citado (RN, RR, PM, CB, D, Q, RSG, E, E2E, M, EC)
     está definido en algún documento.
  3. Todo documento de docs/ aparece en el índice docs/README.md.

Uso:  python scripts/verificar_docs.py docs
Sale con código 1 si encuentra problemas.
"""
import os
import re
import sys
import unicodedata

PREFIJOS = r"(?:RN|RR|PM|CB|D|Q|RSG|E|M)-\d{2}|E2E-\d{2}|EC-\d{3}"
REF = re.compile(r"(?<![\w-])(" + PREFIJOS + r")(?![\w-])")

# Formas de definir un identificador:
#   | **RN-01** | …   | RN-01 | …   | ~~E-14~~ | …   (primera celda de una tabla)
#   - **RN-07** …                                    (viñeta en negrita)
#   ### M-01 · …   ### EC-001 · …                    (encabezado)
DEF_TABLA = re.compile(r"^\|\s*(?:\*\*|~~)?(" + PREFIJOS + r")(?:\*\*|~~)?\s*\|", re.M)
DEF_VINETA = re.compile(r"^\s*-\s+\*\*(" + PREFIJOS + r")\*\*", re.M)
DEF_TITULO = re.compile(r"^#{2,4}\s+(" + PREFIJOS + r")\b", re.M)

ENLACE = re.compile(r"\]\(([^)\s]+)\)")
TITULO = re.compile(r"^#{1,6}\s+(.*)$", re.M)
BLOQUE_CODIGO = re.compile(r"```.*?```", re.S)


def sin_codigo(texto: str) -> str:
    texto = BLOQUE_CODIGO.sub("", texto)
    return re.sub(r"`[^`\n]*`", "", texto)


def ancla(titulo: str) -> str:
    """Ancla al estilo de GitHub: minúsculas, sin puntuación, espacios → guiones."""
    titulo = titulo.strip().lower()
    salida = []
    for c in titulo:
        cat = unicodedata.category(c)
        if c in " -_" or cat[0] in ("L", "N"):
            salida.append(c)
    return "".join(salida).replace(" ", "-")


def anclas_de(ruta: str) -> set:
    texto = BLOQUE_CODIGO.sub("", open(ruta, encoding="utf-8").read())
    vistas, resultado = {}, set()
    for m in TITULO.finditer(texto):
        base = ancla(re.sub(r"`", "", m.group(1)))
        n = vistas.get(base, 0)
        resultado.add(base if n == 0 else f"{base}-{n}")
        vistas[base] = n + 1
    return resultado


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    raiz = sys.argv[1] if len(sys.argv) > 1 else "docs"
    if not os.path.isdir(raiz):
        print(f"No existe la carpeta {raiz}")
        return 1

    docs = sorted(
        os.path.join(raiz, f) for f in os.listdir(raiz) if f.endswith(".md")
    )
    problemas = []
    cache_anclas = {}
    definidos, citados = set(), {}

    for ruta in docs:
        crudo = open(ruta, encoding="utf-8").read()
        texto = sin_codigo(crudo)
        nombre = os.path.basename(ruta)

        for patron in (DEF_TABLA, DEF_VINETA, DEF_TITULO):
            definidos.update(m.group(1) for m in patron.finditer(texto))
        for m in REF.finditer(texto):
            citados.setdefault(m.group(1), set()).add(nombre)

        for m in ENLACE.finditer(BLOQUE_CODIGO.sub("", crudo)):
            destino = m.group(1)
            if destino.startswith(("http://", "https://", "mailto:")):
                continue
            archivo, _, fragmento = destino.partition("#")
            objetivo = (
                os.path.normpath(os.path.join(os.path.dirname(ruta), archivo))
                if archivo else ruta
            )
            if not os.path.exists(objetivo):
                problemas.append(f"{nombre}: enlace roto → {destino}")
                continue
            if fragmento and objetivo.endswith(".md"):
                if objetivo not in cache_anclas:
                    cache_anclas[objetivo] = anclas_de(objetivo)
                if fragmento not in cache_anclas[objetivo]:
                    problemas.append(f"{nombre}: ancla inexistente → {destino}")

    for ident in sorted(citados):
        if ident not in definidos:
            problemas.append(
                f"identificador sin definir: {ident} (citado en {', '.join(sorted(citados[ident]))})"
            )

    indice = os.path.join(raiz, "README.md")
    if os.path.exists(indice):
        texto_indice = open(indice, encoding="utf-8").read()
        for ruta in docs:
            nombre = os.path.basename(ruta)
            if nombre != "README.md" and f"({nombre}" not in texto_indice:
                problemas.append(f"README.md: el índice no enlaza {nombre}")

    if problemas:
        print(f"Se encontraron {len(problemas)} problema(s) en {raiz}/:")
        for p in problemas:
            print(f"  - {p}")
        return 1

    print(
        f"docs/ consistente: {len(docs)} documentos, "
        f"{len(definidos)} identificadores definidos, {len(citados)} citados."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
