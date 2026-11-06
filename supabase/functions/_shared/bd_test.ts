import {
  assert,
  assertEquals,
  assertInstanceOf,
  assertRejects,
  assertThrows,
} from "@std/assert";
import {
  consultaDeFuncion,
  crearBd,
  crearBdConEjecutor,
  type Ejecutor,
  ErrorDeBd,
  prepararArgumento,
} from "./bd.ts";

/** Ejecutor falso: anota lo que recibe y devuelve las filas indicadas. */
function ejecutorFalso(filas: Record<string, unknown>[] = []) {
  const llamadas: { consulta: string; parametros: readonly unknown[] }[] = [];
  let cerrado = 0;
  const ejecutor: Ejecutor = {
    ejecutar(consulta, parametros) {
      llamadas.push({ consulta, parametros });
      return Promise.resolve(filas);
    },
    cerrar() {
      cerrado++;
      return Promise.resolve();
    },
  };
  return { ejecutor, llamadas, cerrados: () => cerrado };
}

// La consulta ------------------------------------------------------------------------------

Deno.test("la consulta llama a private con parámetros enlazados", () => {
  assertEquals(
    consultaDeFuncion("ahora", 0),
    'select * from private."ahora"()',
  );
  assertEquals(
    consultaDeFuncion("guardar_barras_diarias", 1),
    'select * from private."guardar_barras_diarias"($1)',
  );
  assertEquals(
    consultaDeFuncion("validar_operacion", 3),
    'select * from private."validar_operacion"($1, $2, $3)',
  );
});

Deno.test("un nombre que no es de una función simple se rechaza", () => {
  const invalidos = [
    "",
    " ahora",
    "ahora ",
    "Ahora",
    "ahora()",
    "ahora;",
    "ahora; drop table x",
    'ahora"',
    "private.ahora",
    "public.ping",
    "pg_catalog.pg_sleep",
    "1ahora",
    "_ahora",
    "ahora-uno",
    "a b",
    "ahora--",
    "ahora/*x*/",
  ];
  for (const nombre of invalidos) {
    assertThrows(
      () => consultaDeFuncion(nombre, 0),
      ErrorDeBd,
      "Nombre de función inválido",
      `debía rechazar ${JSON.stringify(nombre)}`,
    );
  }
});

Deno.test("la cantidad de argumentos debe ser razonable", () => {
  assertThrows(() => consultaDeFuncion("ahora", -1), ErrorDeBd);
  assertThrows(() => consultaDeFuncion("ahora", 1.5), ErrorDeBd);
  assertThrows(() => consultaDeFuncion("ahora", 101), ErrorDeBd);
});

// Los argumentos ---------------------------------------------------------------------------

Deno.test("los argumentos se preparan según su tipo", () => {
  assertEquals(prepararArgumento("QQQ"), "QQQ");
  assertEquals(prepararArgumento(7), 7);
  assertEquals(prepararArgumento(true), true);
  assertEquals(prepararArgumento(null), null);
  assertEquals(
    prepararArgumento(new Date("2026-11-05T12:30:00Z")),
    "2026-11-05T12:30:00.000Z",
  );
  // Los objetos y arreglos NO se convierten a texto: el cliente los serializa según el tipo
  // del parámetro. Convertidos aquí llegarían a un jsonb como un texto JSON, no como un arreglo.
  const objeto = { a: 1 };
  const arreglo = [{ simbolo: "QQQ" }];
  assertEquals(prepararArgumento(objeto), objeto);
  assertEquals(prepararArgumento(arreglo), arreglo);
});

Deno.test("llamar envía los argumentos enlazados y en orden, sin meterlos en el SQL", async () => {
  const { ejecutor, llamadas } = ejecutorFalso([{ n: 2 }]);
  const bd = crearBdConEjecutor(ejecutor);
  const peligroso = "'; drop table public.lista_blanca; --";

  const filas = await bd.llamar("simbolos_sin_historia", [peligroso, 5, null, [{
    x: 1,
  }]]);

  assertEquals(filas, [{ n: 2 }]);
  assertEquals(llamadas.length, 1);
  assertEquals(
    llamadas[0].consulta,
    'select * from private."simbolos_sin_historia"($1, $2, $3, $4)',
  );
  assert(!llamadas[0].consulta.includes("drop"), "el SQL no lleva los valores");
  assertEquals(llamadas[0].parametros, [peligroso, 5, null, [{ x: 1 }]]);
});

Deno.test("sin argumentos se llama con paréntesis vacíos", async () => {
  const { ejecutor, llamadas } = ejecutorFalso();
  await crearBdConEjecutor(ejecutor).llamar("ahora");
  assertEquals(llamadas[0].consulta, 'select * from private."ahora"()');
  assertEquals(llamadas[0].parametros, []);
});

Deno.test("un nombre inválido se rechaza antes de llegar al ejecutor", async () => {
  const { ejecutor, llamadas } = ejecutorFalso();
  const bd = crearBdConEjecutor(ejecutor);
  await assertRejects(
    () => bd.llamar("public.ping"),
    ErrorDeBd,
    "Nombre de función inválido",
  );
  await assertRejects(() => bd.llamar('x"; select 1; --'), ErrorDeBd);
  assertEquals(llamadas.length, 0);
});

// Errores ----------------------------------------------------------------------------------

Deno.test("un error de la función conserva su código y su mensaje", async () => {
  const error = Object.assign(
    new Error("guardar_barras_diarias: se esperaba un arreglo"),
    {
      code: "P0001",
    },
  );
  const bd = crearBdConEjecutor({
    ejecutar: () => Promise.reject(error),
    cerrar: () => Promise.resolve(),
  });
  const fallo = await assertRejects(
    () => bd.llamar("guardar_barras_diarias", [{}]),
    ErrorDeBd,
    "guardar_barras_diarias: se esperaba un arreglo",
  );
  assertEquals((fallo as ErrorDeBd).codigo, "P0001");
});

Deno.test("los errores no copian la URL, el usuario ni la contraseña", async () => {
  const url =
    "postgresql://postgres.abcdef:clave-muy-secreta@servidor.interno:5432/postgres";
  const bd = crearBdConEjecutor(
    {
      ejecutar: () =>
        Promise.reject(
          new Error(
            `no se pudo conectar a ${url} con clave-muy-secreta (postgres.abcdef)`,
          ),
        ),
      cerrar: () => Promise.resolve(),
    },
    [url, "clave-muy-secreta", "postgres.abcdef"],
  );
  const fallo = await assertRejects(() => bd.llamar("ahora"), ErrorDeBd);
  assertInstanceOf(fallo, ErrorDeBd);
  assert(!fallo.message.includes("clave-muy-secreta"), fallo.message);
  assert(!fallo.message.includes("postgres.abcdef"), fallo.message);
  assert(!fallo.message.includes(url), fallo.message);
});

Deno.test("cerrar cierra el ejecutor", async () => {
  const { ejecutor, cerrados } = ejecutorFalso();
  await crearBdConEjecutor(ejecutor).cerrar();
  assertEquals(cerrados(), 1);
});

// crearBd ----------------------------------------------------------------------------------

/** Ejecuta `prueba` con SUPABASE_DB_URL borrada y la restaura después. */
async function sinUrl(prueba: () => void | Promise<void>) {
  const original = Deno.env.get("SUPABASE_DB_URL");
  Deno.env.delete("SUPABASE_DB_URL");
  try {
    await prueba();
  } finally {
    if (original !== undefined) Deno.env.set("SUPABASE_DB_URL", original);
  }
}

Deno.test("sin URL, crearBd nombra la variable que falta", async () => {
  await sinUrl(() => {
    const error = assertThrows(() => crearBd(), ErrorDeBd, "SUPABASE_DB_URL");
    assertEquals(error.name, "ErrorDeBd");
  });
});

Deno.test("una URL inválida se rechaza sin copiarla en el mensaje", async () => {
  await sinUrl(() => {
    const error = assertThrows(
      () => crearBd({ url: "esto-no-es-una-url-con-clave-xyz" }),
      ErrorDeBd,
      "SUPABASE_DB_URL",
    );
    assert(!error.message.includes("clave-xyz"), error.message);
  });
});

Deno.test("la URL de SUPABASE_DB_URL se usa por defecto y no abre la conexión hasta llamar", async () => {
  const original = Deno.env.get("SUPABASE_DB_URL");
  Deno.env.set("SUPABASE_DB_URL", "postgresql://u:p@127.0.0.1:1/postgres");
  try {
    const bd = crearBd();
    await bd.cerrar(); // no hubo conexión: cerrar no falla
  } finally {
    if (original === undefined) Deno.env.delete("SUPABASE_DB_URL");
    else Deno.env.set("SUPABASE_DB_URL", original);
  }
});

Deno.test("una conexión que falla no filtra la contraseña", async () => {
  // Puerto 1 de la propia máquina: la conexión se rechaza al instante.
  const bd = crearBd({
    url: "postgresql://usuario-x:clave-muy-secreta@127.0.0.1:1/postgres",
  });
  try {
    const fallo = await assertRejects(() => bd.llamar("ahora"), ErrorDeBd);
    assert(!fallo.message.includes("clave-muy-secreta"), fallo.message);
    assert(!fallo.message.includes("postgresql://"), fallo.message);
  } finally {
    await bd.cerrar();
  }
});
