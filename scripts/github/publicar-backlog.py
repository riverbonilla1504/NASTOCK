#!/usr/bin/env python3
"""Publica backlog/ como issues de GitHub y los organiza en GitHub Projects.

Crea (de forma idempotente: se puede correr varias veces):

1. Una issue por épica (E-01 … E-13), por historia (HU-xxx) y por tarea
   técnica (TT-xx), con el contenido de su archivo de backlog/, sus etiquetas
   y su hito (entrega). El título es "<ID> · <nombre>"; con ese prefijo se
   reconoce una issue ya creada.
2. Los enlaces entre ítems del backlog se cambian por referencias #n; los
   demás enlaces relativos apuntan al archivo en la rama main.
3. Cada historia o tarea como sub-issue de su épica.
4. Las relaciones "Depende de" como dependencias de GitHub (bloqueada por).
5. Con --proyecto: cada historia y tarea técnica en el proyecto, con los
   campos Épica, Entrega, Prioridad y Módulos, y Status = Backlog. Las épicas
   no van al tablero (no se trabajan): quedan como issues padre.

Uso:       python scripts/github/publicar-backlog.py <dueño>/<repo> [--proyecto N] [--simular]
Requisito: scripts/github/preparar-github.sh ya ejecutado (etiquetas, hitos,
           proyecto) y, para --proyecto, gh auth refresh -s project.

Detalle: docs/16-arranque-del-repositorio.md §6.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
BACKLOG = RAIZ / "backlog"
ENLACE = re.compile(r"\[([^\]]*)\]\(([^)\s]+)\)")
ID_ITEM = re.compile(r"^(HU-\d{3}|TT-\d{2})-")
ID_EPICA = re.compile(r"^(E-\d{2})-")


@dataclass
class Item:
    id: str                      # E-02, HU-005, TT-01
    tipo: str                    # epica, historia, tarea-tecnica
    ruta: Path
    titulo: str                  # "HU-005 · Ingresar con Google…"
    epica: str                   # E-02
    campos: dict[str, str]
    etiquetas: list[str]
    contenido: str               # markdown sin el título H1
    depende_de: list[str] = field(default_factory=list)
    numero: int | None = None
    node_id: str | None = None   # id interno de la issue (sub-issues, dependencias)
    graphql_id: str | None = None

    @property
    def entrega(self) -> str | None:
        hito = self.campos.get("Entrega (hito)")
        return hito.split(" ")[0] if hito else None

    @property
    def modulos(self) -> str:
        return self.campos.get("Módulos afectados") or self.campos.get("Módulos (docs/17)", "")


# Fallos de transporte o del servidor, no de la petición: se pueden repetir.
TRANSITORIO = re.compile(r"TLS handshake timeout|stream error|connection reset|i/o timeout|"
                         r"Something went wrong|HTTP 50[234]", re.I)


def gh(*args: str, entrada: str | None = None, permitir_error: bool = False) -> str:
    # "issue create" no es idempotente: repetirlo tras un fallo podría duplicar la issue.
    intentos = 1 if args[:2] == ("issue", "create") else 4
    for intento in range(intentos):
        r = subprocess.run(["gh", *args], input=entrada, capture_output=True,
                           text=True, encoding="utf-8")
        if r.returncode == 0 or not TRANSITORIO.search(r.stderr):
            break
        time.sleep(5 * (intento + 1))
    if r.returncode != 0 and not permitir_error:
        raise RuntimeError(f"gh {' '.join(args[:3])}…: {r.stderr.strip()}")
    return r.stdout if r.returncode == 0 else ""


def gh_json(*args: str, **kw):
    salida = gh(*args, **kw)
    return json.loads(salida) if salida.strip() else None


def graphql(consulta: str, **variables) -> dict:
    args = ["api", "graphql", "-f", f"query={consulta}"]
    for k, v in variables.items():
        args += ["-F" if isinstance(v, int) else "-f", f"{k}={v}"]
    return json.loads(gh(*args))["data"]


# --- Lectura del backlog ---------------------------------------------------

def tabla_inicial(texto: str) -> dict[str, str]:
    campos = {}
    for linea in texto.splitlines():
        m = re.match(r"^\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|$", linea)
        if m and m.group(1) not in ("Campo", "---"):
            campos[m.group(1)] = m.group(2)
        elif campos and not linea.startswith("|"):
            break
    return campos


def leer_item(ruta: Path, tipo: str, ident: str, epica: str) -> Item:
    texto = ruta.read_text(encoding="utf-8")
    primera, _, resto = texto.partition("\n")
    titulo = primera.lstrip("# ").strip()
    campos = tabla_inicial(resto)
    etiquetas = re.findall(r"`([^`]+)`", campos.get("Etiquetas", ""))
    depende = []
    for linea in resto.splitlines():
        if linea.startswith("| Depende de |"):
            depende += [m.group(1) for m in re.finditer(r"\[((?:HU|TT)-\d+)", linea)]
    return Item(ident, tipo, ruta, titulo, epica, campos, etiquetas,
                resto.lstrip("\n"), depende if tipo != "epica" else [])


def leer_backlog() -> list[Item]:
    items = []
    for carpeta in sorted(BACKLOG.glob("E-*")):
        epica = ID_EPICA.match(carpeta.name).group(1)
        items.append(leer_item(carpeta / "README.md", "epica", epica, epica))
        for ruta in sorted(carpeta.glob("*.md")):
            m = ID_ITEM.match(ruta.name)
            if m:
                tipo = "historia" if m.group(1).startswith("HU") else "tarea-tecnica"
                items.append(leer_item(ruta, tipo, m.group(1), epica))
    return items


# --- Cuerpo de la issue ----------------------------------------------------

def cuerpo(item: Item, por_ruta: dict[Path, Item], repo: str) -> str:
    base = item.ruta.parent

    def cambiar(m: re.Match) -> str:
        texto, destino = m.group(1), m.group(2)
        if re.match(r"^[a-z]+:|^#", destino):
            return m.group(0)
        ruta, _, ancla = destino.partition("#")
        absoluta = (base / ruta).resolve()
        otro = por_ruta.get(absoluta)
        if otro and otro.numero and not ancla:
            return f"{texto} (#{otro.numero})"
        rel = absoluta.relative_to(RAIZ).as_posix()
        clase = "tree" if absoluta.is_dir() else "blob"
        url = f"https://github.com/{repo}/{clase}/main/{rel}" + (f"#{ancla}" if ancla else "")
        return f"[{texto}]({url})"

    fuente = item.ruta.relative_to(RAIZ).as_posix()
    pie = (f"\n\n---\n\nFuente: [`{fuente}`](https://github.com/{repo}/blob/main/{fuente}) · "
           "`docs/` es la fuente de verdad (ver `CLAUDE.md`).\n")
    return ENLACE.sub(cambiar, item.contenido).rstrip() + pie


# --- GitHub ----------------------------------------------------------------

def issues_existentes(repo: str) -> dict[str, dict]:
    datos = gh_json("issue", "list", "-R", repo, "--state", "all", "--limit", "1000",
                    "--json", "number,title,id,body")
    existentes = {}
    for i in datos or []:
        m = re.match(r"^((?:E|HU|TT)-\d+) · ", i["title"])
        if m:
            existentes[m.group(1)] = i
    return existentes


def crear_o_actualizar(item: Item, repo: str, cuerpo_md: str, existente: dict | None,
                       simular: bool) -> str:
    if simular:
        return "simulada"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8",
                                     newline="\n") as f:
        f.write(cuerpo_md)
        archivo = f.name
    try:
        if existente is None:
            args = ["issue", "create", "-R", repo, "--title", item.titulo, "--body-file", archivo]
            for e in item.etiquetas:
                args += ["--label", e]
            if item.tipo != "epica" and item.campos.get("Entrega (hito)"):
                args += ["--milestone", item.campos["Entrega (hito)"]]
            url = gh(*args).strip()
            item.numero = int(url.rsplit("/", 1)[1])
            time.sleep(1.5)  # límite secundario de creación de contenido
            return "creada"
        item.numero = existente["number"]
        item.graphql_id = existente["id"]
        # GitHub conserva los \r\n del archivo; se comparan sin ellos.
        if existente["body"].replace("\r\n", "\n").strip() != cuerpo_md.strip():
            gh("issue", "edit", str(item.numero), "-R", repo, "--body-file", archivo)
            return "actualizada"
        return "sin cambios"
    finally:
        os.unlink(archivo)


def enlazar_sub_issues(items: list[Item], repo: str) -> None:
    epicas = {i.id: i for i in items if i.tipo == "epica"}
    for epica in epicas.values():
        hijas = gh_json("api", f"repos/{repo}/issues/{epica.numero}/sub_issues?per_page=100",
                        "--paginate") or []
        ya = {h["number"] for h in hijas}
        for item in items:
            if item.tipo != "epica" and item.epica == epica.id and item.numero not in ya:
                gh("api", "-X", "POST", f"repos/{repo}/issues/{epica.numero}/sub_issues",
                   "-F", f"sub_issue_id={item.node_id}")
                print(f"  sub-issue: {item.id} → {epica.id}")


def enlazar_dependencias(items: list[Item], repo: str) -> None:
    por_id = {i.id: i for i in items}
    for item in items:
        if not item.depende_de:
            continue
        actuales = gh_json("api", f"repos/{repo}/issues/{item.numero}/dependencies/blocked_by",
                           permitir_error=True)
        if actuales is None:
            print("  (las dependencias de issues no están disponibles en este repositorio)")
            return
        ya = {d["number"] for d in actuales}
        for dep in item.depende_de:
            otro = por_id.get(dep)
            if otro and otro.numero not in ya:
                gh("api", "-X", "POST",
                   f"repos/{repo}/issues/{item.numero}/dependencies/blocked_by",
                   "-F", f"issue_id={otro.node_id}", permitir_error=True)
                print(f"  dependencia: {item.id} bloqueada por {dep}")


def organizar_en_proyecto(items: list[Item], dueno: str, numero: int) -> None:
    datos = graphql("""
      query($dueno: String!, $numero: Int!) {
        user(login: $dueno) { projectV2(number: $numero) { id
          fields(first: 50) { nodes {
            ... on ProjectV2FieldCommon { id name }
            ... on ProjectV2SingleSelectField { options { id name } } } } } } }""",
                    dueno=dueno, numero=numero)
    proyecto = datos["user"]["projectV2"]
    campos = {c["name"]: c for c in proyecto["fields"]["nodes"] if c}

    def opcion(nombre_campo: str, valor: str | None) -> tuple[str, str] | None:
        c = campos.get(nombre_campo)
        if not c or not valor:
            return None
        for o in c.get("options", []):
            if o["name"] == valor:
                return c["id"], o["id"]
        return None

    for item in items:
        if item.tipo == "epica":
            # Las épicas no se trabajan: quedan fuera del tablero, como issues padre.
            datos = graphql("""
              query($c: ID!) { node(id: $c) { ... on Issue {
                projectItems(first: 20) { nodes { id project { id } } } } } }""", c=item.graphql_id)
            for pi in datos["node"]["projectItems"]["nodes"]:
                if pi["project"]["id"] == proyecto["id"]:
                    graphql("""
                      mutation($p: ID!, $i: ID!) {
                        deleteProjectV2Item(input: {projectId: $p, itemId: $i}) { deletedItemId } }""",
                            p=proyecto["id"], i=pi["id"])
                    print(f"  proyecto: {item.id} retirada del tablero")
            continue
        agregado = graphql("""
          mutation($p: ID!, $c: ID!) {
            addProjectV2ItemById(input: {projectId: $p, contentId: $c}) { item { id } } }""",
                           p=proyecto["id"], c=item.graphql_id)
        item_id = agregado["addProjectV2ItemById"]["item"]["id"]
        cambios = []
        for nombre, valor in (("Épica", item.epica), ("Entrega", item.entrega),
                              ("Prioridad", item.campos.get("Prioridad")),
                              ("Status", "Backlog")):
            par = opcion(nombre, valor)
            if par:
                cambios.append((par[0], f'{{singleSelectOptionId: "{par[1]}"}}'))
        if "Módulos" in campos and item.modulos:
            cambios.append((campos["Módulos"]["id"], json.dumps({"text": item.modulos})
                            .replace('"text"', "text")))
        if cambios:
            partes = [
                f'c{n}: updateProjectV2ItemFieldValue(input: {{projectId: "{proyecto["id"]}", '
                f'itemId: "{item_id}", fieldId: "{campo}", value: {valor}}}) {{ clientMutationId }}'
                for n, (campo, valor) in enumerate(cambios)]
            graphql("mutation {" + "\n".join(partes) + "}")
        print(f"  proyecto: {item.id}")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("repo", help="<dueño>/<repo>")
    p.add_argument("--proyecto", type=int, help="número del proyecto de GitHub")
    p.add_argument("--simular", action="store_true", help="solo muestra lo que haría")
    a = p.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    items = leer_backlog()
    por_ruta = {i.ruta.resolve(): i for i in items}
    print(f"Backlog: {sum(i.tipo == 'epica' for i in items)} épicas, "
          f"{sum(i.tipo == 'historia' for i in items)} historias, "
          f"{sum(i.tipo == 'tarea-tecnica' for i in items)} tareas técnicas")

    existentes = issues_existentes(a.repo)
    for i in items:
        if i.id in existentes:
            i.numero = existentes[i.id]["number"]

    # Primera pasada: crear lo que falta. Segunda: cuerpos con todas las #n.
    print("Issues…")
    for i in items:
        if i.id not in existentes:
            estado = crear_o_actualizar(i, a.repo, cuerpo(i, por_ruta, a.repo), None, a.simular)
            print(f"  {estado}: {i.titulo}" + (f" (#{i.numero})" if i.numero else ""))
    if a.simular:
        return 0

    existentes = issues_existentes(a.repo)
    for i in items:
        estado = crear_o_actualizar(i, a.repo, cuerpo(i, por_ruta, a.repo), existentes[i.id], False)
        if estado != "sin cambios":
            print(f"  {estado}: {i.id} (#{i.numero})")

    paginas = gh_json("api", f"repos/{a.repo}/issues?state=all&per_page=100",
                      "--paginate", "--slurp") or []
    internos = {d["number"]: d["id"] for pagina in paginas for d in pagina}
    for i in items:
        i.node_id = str(internos[i.numero])

    print("Sub-issues…")
    enlazar_sub_issues(items, a.repo)
    print("Dependencias…")
    enlazar_dependencias(items, a.repo)

    if a.proyecto:
        print(f"Proyecto #{a.proyecto}…")
        organizar_en_proyecto(items, a.repo.split("/")[0], a.proyecto)
    else:
        print("Sin --proyecto: las issues no se agregaron a GitHub Projects.")
    print("Listo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
