#!/usr/bin/env python3
"""Genera las páginas de la wiki a partir de docs/ (la fuente de verdad).

- Cada docs/NN-nombre.md se publica como la página "NN-nombre".
- docs/README.md se publica como "Home".
- Los enlaces entre documentos se adaptan al formato de la wiki
  (sin ".md"); los enlaces a archivos fuera de docs/ apuntan al repositorio.
- Se genera _Sidebar.md con el orden del índice y _Footer.md con el commit.
- Cada página lleva un aviso: la wiki no se edita a mano.

Uso:  python scripts/publicar_wiki.py docs <carpeta-del-clon-de-la-wiki>
Variables opcionales: GITHUB_REPOSITORY (dueño/repo), GITHUB_SHA.
"""
import os
import re
import sys

BLOQUE_CODIGO = re.compile(r"(```.*?```)", re.S)
ENLACE = re.compile(r"\]\(([^)\s]+)\)")


def pagina(nombre_md: str) -> str:
    return "Home" if nombre_md == "README.md" else nombre_md[:-3]


def adaptar_enlaces(texto: str, docs: set, repo: str) -> str:
    def reemplazar(m):
        destino = m.group(1)
        if destino.startswith(("http://", "https://", "mailto:", "#")):
            return m.group(0)
        archivo, sep, fragmento = destino.partition("#")
        if archivo in docs:
            return f"]({pagina(archivo)}{sep}{fragmento})"
        if archivo.startswith("../") and repo:
            ruta = archivo[3:]
            return f"](https://github.com/{repo}/blob/main/{ruta}{sep}{fragmento})"
        return m.group(0)

    partes = BLOQUE_CODIGO.split(texto)
    return "".join(
        p if p.startswith("```") else ENLACE.sub(reemplazar, p) for p in partes
    )


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    carpeta_docs, carpeta_wiki = sys.argv[1], sys.argv[2]
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    sha = os.environ.get("GITHUB_SHA", "")[:7]

    docs = sorted(f for f in os.listdir(carpeta_docs) if f.endswith(".md"))
    conjunto = set(docs)

    # Se reemplaza el contenido completo: lo que ya no existe en docs/ desaparece.
    for f in os.listdir(carpeta_wiki):
        if f.endswith(".md"):
            os.remove(os.path.join(carpeta_wiki, f))

    origen = f"https://github.com/{repo}/tree/main/docs" if repo else "docs/"
    aviso = (
        f"> Página generada automáticamente desde [`docs/`]({origen}). "
        "No la edites aquí: los cambios se pierden en la siguiente publicación.\n\n"
    )

    for nombre in docs:
        texto = open(os.path.join(carpeta_docs, nombre), encoding="utf-8").read()
        texto = adaptar_enlaces(texto, conjunto, repo)
        with open(os.path.join(carpeta_wiki, pagina(nombre) + ".md"), "w", encoding="utf-8") as salida:
            salida.write(aviso + texto)

    # Barra lateral en el orden en que el índice enlaza los documentos.
    indice = open(os.path.join(carpeta_docs, "README.md"), encoding="utf-8").read()
    orden, vistos = [], set()
    # Solo filas de tabla y enlaces sin ancla: así se respeta el orden del índice.
    filas = "\n".join(l for l in indice.splitlines() if l.startswith("|"))
    for m in re.finditer(r"\[([^\]]+)\]\(([^)#\s]+\.md)\)", filas):
        titulo, archivo = m.group(1), m.group(2)
        if archivo in conjunto and archivo not in vistos and archivo != "README.md":
            orden.append((titulo, archivo))
            vistos.add(archivo)
    lineas = ["**RiTech SAS · Especificación**", "", "- [Inicio](Home)"]
    for titulo, archivo in orden:
        prefijo = archivo.split("-")[0] if archivo[:2].isdigit() else "·"
        lineas.append(f"- [{prefijo} {titulo}]({pagina(archivo)})")
    with open(os.path.join(carpeta_wiki, "_Sidebar.md"), "w", encoding="utf-8") as salida:
        salida.write("\n".join(lineas) + "\n")

    with open(os.path.join(carpeta_wiki, "_Footer.md"), "w", encoding="utf-8") as salida:
        salida.write(f"Fuente: `docs/` del repositorio{f' · commit {sha}' if sha else ''}.\n")

    print(f"Wiki generada: {len(docs)} páginas.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
