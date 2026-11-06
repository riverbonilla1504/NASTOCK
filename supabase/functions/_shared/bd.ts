// Única puerta de las Edge Functions a Postgres (D-66, docs/05 §6, docs/06 §7 regla 3).
//
// Las funciones se conectan directo a la base con SUPABASE_DB_URL (la da la plataforma) y
// SOLO ejecutan funciones del esquema `private`: supabase-js pasa por la API de datos, que
// no expone `private`. Este es el único archivo de supabase/functions que importa el
// cliente de Postgres; scripts/verificar.sh y el trabajo `arquitectura` de CI lo vigilan.
//
// Qué garantiza:
//   - El nombre de la función se valida (`^[a-z][a-z0-9_]*$`) y se antepone `private.`:
//     no se puede nombrar otro esquema ni pasar SQL en el nombre.
//   - Los argumentos van como parámetros enlazados ($1, $2…), nunca dentro del texto SQL.
//   - Los errores no copian la URL de conexión, el usuario ni la contraseña.

import postgres from "postgres";

/** Valores que se pueden pasar a una función. Los objetos y arreglos llegan como jsonb si la función lo pide. */
export type Argumento =
  | string
  | number
  | boolean
  | null
  | Date
  | readonly unknown[]
  | Record<string, unknown>;

/** Lo que puede hacer una función con la base. */
export interface Bd {
  /** Ejecuta `private.<funcion>(...argumentos)` y devuelve sus filas. */
  llamar<T = Record<string, unknown>>(
    funcion: string,
    argumentos?: readonly Argumento[],
  ): Promise<T[]>;
  /** Cierra la conexión. Llamarla siempre al terminar (por ejemplo, en un `finally`). */
  cerrar(): Promise<void>;
}

/** Fallo de la base o de su configuración. El mensaje nunca trae secretos. */
export class ErrorDeBd extends Error {
  constructor(mensaje: string, readonly codigo?: string) {
    super(mensaje);
    this.name = "ErrorDeBd";
  }
}

/** Cómo se ejecuta una consulta con parámetros enlazados; las pruebas usan uno falso. */
export interface Ejecutor {
  ejecutar(
    consulta: string,
    parametros: readonly unknown[],
  ): Promise<Record<string, unknown>[]>;
  cerrar(): Promise<void>;
}

const NOMBRE_DE_FUNCION = /^[a-z][a-z0-9_]*$/;

/** Postgres admite hasta 100 parámetros en una función; una cantidad mayor es un error de uso. */
const MAXIMO_DE_ARGUMENTOS = 100;

/**
 * Consulta que ejecuta `private.<funcion>` con `cantidad` parámetros enlazados.
 * Lanza ErrorDeBd si el nombre no es el de una función simple.
 */
export function consultaDeFuncion(funcion: string, cantidad: number): string {
  if (typeof funcion !== "string" || !NOMBRE_DE_FUNCION.test(funcion)) {
    throw new ErrorDeBd(
      "Nombre de función inválido: solo minúsculas, números y guion bajo, sin esquema",
    );
  }
  if (
    !Number.isInteger(cantidad) || cantidad < 0 ||
    cantidad > MAXIMO_DE_ARGUMENTOS
  ) {
    throw new ErrorDeBd("Cantidad de argumentos inválida");
  }
  const marcadores = Array.from({ length: cantidad }, (_, i) => `$${i + 1}`);
  return `select * from private."${funcion}"(${marcadores.join(", ")})`;
}

/**
 * Valor que se envía como parámetro. Las fechas viajan como texto ISO. Los objetos y arreglos
 * se pasan tal cual: el cliente los serializa según el tipo que la base declara para el
 * parámetro (a JSON si es jsonb, a arreglo de Postgres si es un arreglo). No se convierten a
 * texto aquí: un jsonb ya convertido a texto se serializaría dos veces y llegaría como un
 * texto JSON, no como un arreglo u objeto.
 */
export function prepararArgumento(argumento: Argumento): unknown {
  if (argumento instanceof Date) return argumento.toISOString();
  return argumento;
}

/** Quita de un texto la URL de conexión y sus partes sensibles. */
function limpiar(texto: string, secretos: readonly string[]): string {
  let limpio = texto;
  for (const secreto of secretos) {
    if (secreto) limpio = limpio.split(secreto).join("***");
  }
  return limpio;
}

/**
 * Bd sobre un ejecutor cualquiera. `secretos` son textos (URL, usuario, contraseña) que no
 * deben aparecer en ningún mensaje de error.
 */
export function crearBdConEjecutor(
  ejecutor: Ejecutor,
  secretos: readonly string[] = [],
): Bd {
  return {
    async llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ): Promise<T[]> {
      const consulta = consultaDeFuncion(funcion, argumentos.length);
      try {
        const filas = await ejecutor.ejecutar(
          consulta,
          argumentos.map(prepararArgumento),
        );
        return filas as T[];
      } catch (error) {
        if (error instanceof ErrorDeBd) throw error;
        // PostgresError trae `code` (SQLSTATE) y el mensaje de la propia función de private.
        const codigo = (error as { code?: unknown } | null)?.code;
        const mensaje = error instanceof Error ? error.message : String(error);
        throw new ErrorDeBd(
          `private.${funcion} falló: ${limpiar(mensaje, secretos)}`,
          typeof codigo === "string" ? codigo : undefined,
        );
      }
    },
    async cerrar(): Promise<void> {
      await ejecutor.cerrar();
    },
  };
}

/** Partes de la URL que no pueden aparecer en un mensaje. */
function secretosDe(url: string): string[] {
  const secretos = [url];
  try {
    const partes = new URL(url);
    for (const parte of [partes.password, partes.username]) {
      if (parte) secretos.push(decodeURIComponent(parte));
    }
  } catch {
    // La URL inválida se informa en crearBd, sin copiarla.
  }
  return secretos;
}

/**
 * Bd conectada a Postgres. La conexión se abre en la primera llamada.
 * `url` es SUPABASE_DB_URL por defecto.
 */
export function crearBd(opciones: { url?: string } = {}): Bd {
  const url = opciones.url ?? Deno.env.get("SUPABASE_DB_URL");
  if (!url) {
    throw new ErrorDeBd(
      "Falta SUPABASE_DB_URL: la entrega la plataforma a las Edge Functions (docs/05 §10.1)",
    );
  }
  try {
    new URL(url);
  } catch {
    throw new ErrorDeBd("SUPABASE_DB_URL no es una URL de conexión válida");
  }

  let sql: ReturnType<typeof postgres> | undefined;
  const ejecutor: Ejecutor = {
    async ejecutar(consulta, parametros) {
      // Una conexión por instancia; sin sentencias preparadas, para que funcione también
      // detrás del pooler en modo transacción.
      sql ??= postgres(url, {
        max: 1,
        prepare: false,
        connect_timeout: 10,
        idle_timeout: 20,
        onnotice: () => {},
      });
      const filas = await sql.unsafe(consulta, parametros as never[]);
      return filas.map((fila) => ({ ...fila }));
    },
    async cerrar() {
      const actual = sql;
      sql = undefined;
      await actual?.end({ timeout: 5 });
    },
  };
  return crearBdConEjecutor(ejecutor, secretosDe(url));
}
