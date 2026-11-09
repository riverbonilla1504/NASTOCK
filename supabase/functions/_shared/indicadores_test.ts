import { assert, assertAlmostEquals, assertEquals } from "@std/assert";
import {
  type BarraDia,
  calcularMetricas,
  elegirCandidatas,
  percentilDe,
  puntajesCuantitativos,
  verificarCalidad,
} from "./indicadores.ts";

/** Serie de `n` días terminando en `ultima`, con cierres que crecen `paso` por día. */
export function serie(
  n: number,
  inicio = 100,
  paso = 1,
  ultima = "2026-11-06",
  ruido = 0,
): BarraDia[] {
  const fin = new Date(`${ultima}T00:00:00Z`);
  return Array.from({ length: n }, (_, i) => {
    const d = new Date(fin);
    d.setUTCDate(d.getUTCDate() - (n - 1 - i));
    const cierre = inicio + paso * i + ruido * Math.sin(i * 1.7);
    return {
      fecha: d.toISOString().slice(0, 10),
      apertura: cierre - 0.2,
      maximo: cierre + 1,
      minimo: cierre - 1,
      cierre,
      volumen: 1000,
    };
  });
}

const contexto = {
  ultimaSesion: "2026-11-06",
  maxAntiguedadSeg: 60,
  exigirPrecioEnVivo: false,
};

Deno.test("calidad: serie sana es ok", () => {
  assertEquals(verificarCalidad(serie(80), contexto), "ok");
});

Deno.test("calidad: menos de 60 barras", () => {
  assertEquals(verificarCalidad(serie(59), contexto), "barras_insuficientes");
});

Deno.test("calidad: última barra distinta de la sesión de referencia", () => {
  assertEquals(
    verificarCalidad(serie(80, 100, 1, "2026-11-05"), contexto),
    "datos_viejos",
  );
});

Deno.test("calidad: valores inválidos", () => {
  const barras = serie(80);
  barras[10] = { ...barras[10], cierre: 0 };
  assertEquals(verificarCalidad(barras, contexto), "valores_invalidos");
});

Deno.test("calidad: salto de más de 25 % en el día", () => {
  const barras = serie(80);
  barras[79] = {
    ...barras[79],
    cierre: barras[78].cierre * 1.3,
    maximo: barras[78].cierre * 1.4,
  };
  assertEquals(verificarCalidad(barras, contexto), "salto_anomalo");
});

Deno.test("calidad: con el mercado abierto exige un precio en vivo de menos de 60 s", () => {
  const abierto = { ...contexto, exigirPrecioEnVivo: true };
  assertEquals(verificarCalidad(serie(80), abierto), "precio_en_vivo_viejo");
  assertEquals(
    verificarCalidad(serie(80), {
      ...abierto,
      precioEnVivo: { precio: 180, antiguedadSeg: 120 },
    }),
    "precio_en_vivo_viejo",
  );
  assertEquals(
    verificarCalidad(serie(80), {
      ...abierto,
      precioEnVivo: { precio: 180, antiguedadSeg: 15 },
    }),
    "ok",
  );
});

Deno.test("métricas: rendimientos, medias y tendencia de una serie que sube 1 por día", () => {
  const m = calcularMetricas(serie(80));
  // cierre final = 179
  assertAlmostEquals(m.rendimiento_1d, 179 / 178 - 1, 1e-12);
  assertAlmostEquals(m.rendimiento_5d, 179 / 174 - 1, 1e-12);
  assertAlmostEquals(m.rendimiento_20d, 179 / 159 - 1, 1e-12);
  assertAlmostEquals(m.rendimiento_60d, 179 / 119 - 1, 1e-12);
  assertAlmostEquals(m.sma_20, (160 + 179) / 2, 1e-9); // media de 160..179
  assertEquals(m.sma_200, null);
  assertEquals(m.sobre_sma_20, true);
  assertEquals(m.sobre_sma_200, null);
  assertEquals(m.rsi_14, 100);
  assertEquals(m.tendencia_30d, "alcista");
  assertAlmostEquals(m.distancia_maximo_52s, 179 / 180 - 1, 1e-12); // el máximo de la última barra es 180
  assertAlmostEquals(m.volumen_relativo, 1, 1e-12);
  // ATR: rango de cada barra = max(2, |máx − cierre previo| = 2, |mín − cierre previo| = 0) = 2
  assertAlmostEquals(m.atr_14, 2, 1e-9);
});

Deno.test("métricas: el precio en vivo reemplaza al último cierre", () => {
  const m = calcularMetricas(serie(80), 190);
  assertEquals(m.precio, 190);
  assertAlmostEquals(m.rendimiento_1d, 190 / 178 - 1, 1e-12);
});

Deno.test("percentil: el más alto vale 1 y el más bajo 0", () => {
  const todos = [1, 2, 3, 4, 5];
  assertEquals(percentilDe(5, todos), 1);
  assertEquals(percentilDe(1, todos), 0);
  assertEquals(percentilDe(3, todos), 0.5);
});

Deno.test("Q: percentil de 0,6·ra20 + 0,4·ra60 con 0,1 de bonificación sobre la media de 50 días (tope 1)", () => {
  const sube = calcularMetricas(serie(80, 100, 1, "2026-11-06", 2));
  const baja = calcularMetricas(serie(80, 200, -1, "2026-11-06", 2));
  const plana = calcularMetricas(serie(80, 100, 0.01, "2026-11-06", 2));
  const q = puntajesCuantitativos(
    new Map([["SUBE", sube], ["BAJA", baja], ["PLANA", plana]]),
  );
  assert(q.get("SUBE")!.q >= q.get("PLANA")!.q);
  assert(q.get("PLANA")!.q > q.get("BAJA")!.q);
  assertEquals(q.get("SUBE")!.q, 1); // 1 + 0,1 se acota a 1
  assertEquals(q.get("BAJA")!.q, 0); // el más bajo y bajo la media de 50 días
});

Deno.test("candidatas: las N mejores de Arriesgadas y todas las de Usuarios", () => {
  const q = new Map(
    ["A", "B", "C", "D", "QLD", "QQQ"].map((
      s,
      i,
    ) => [s, { q: i / 10, v: 0.5 }]),
  );
  const c = elegirCandidatas(["A", "B", "C", "D", "ZZZ"], ["QLD", "QQQ"], q, 2);
  assertEquals(c.arriesgadas, ["D", "C"]);
  assertEquals(c.usuarios, ["QLD", "QQQ"]);
});
