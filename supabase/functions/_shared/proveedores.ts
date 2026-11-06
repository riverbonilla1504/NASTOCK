// Proveedores reales o simulados (docs/10 §9, docs/05 §6, FR-004 y FR-005).
//
// Cada integración (broker, mercado, noticias, contexto, JEV y push) tiene una
// implementación real y una simulada con la misma interfaz. Cuál se usa lo decide
// una variable de entorno por integración (`PROVEEDOR_BROKER`, `PROVEEDOR_MERCADO`…).
// Este archivo no conoce las implementaciones: cada integración las registra al
// llamar a `elegirProveedor`, y la historia que la construye aporta su simulado.
//
// Regla de seguridad (CB-91): con `ENTORNO=mvp` ninguna integración puede ser
// simulada, para que nunca se mezclen llenados simulados con la cuenta paper. Se
// revisan las seis, no solo la que se pide, y se lanza `ErrorDeConfiguracion`.
//
// Cada función debe llamar a `elegirProveedor` (o a `leerConfiguracion`) al cargar
// el módulo, fuera del manejador de peticiones: así, si la configuración es
// inválida, la función no arranca.

/** Las integraciones con proveedor intercambiable (docs/10 §9). */
export const INTEGRACIONES = [
  "broker",
  "mercado",
  "noticias",
  "contexto",
  "jev",
  "push",
] as const;

export type Integracion = (typeof INTEGRACIONES)[number];

/** Variable de entorno que elige el proveedor de cada integración. */
export const VARIABLE_DE_PROVEEDOR: Readonly<Record<Integracion, string>> = {
  broker: "PROVEEDOR_BROKER",
  mercado: "PROVEEDOR_MERCADO",
  noticias: "PROVEEDOR_NOTICIAS",
  contexto: "PROVEEDOR_CONTEXTO",
  jev: "PROVEEDOR_JEV",
  push: "PROVEEDOR_PUSH",
};

/** Nombre del proveedor simulado, común a todas las integraciones. */
export const SIMULADO = "simulado";

/** Los entornos de docs/05 §10. Solo `mvp` rechaza proveedores simulados. */
export const ENTORNOS = ["local", "ci", "demo", "mvp"] as const;

export type Entorno = (typeof ENTORNOS)[number];

/** Entorno cuando `ENTORNO` no está definido: el de desarrollo, todo simulado (docs/10 §9). */
const ENTORNO_POR_DEFECTO: Entorno = "local";

/** Cómo se leen las variables de entorno; las pruebas pasan una versión falsa. */
export type LeerVariable = (nombre: string) => string | undefined;

const leerDelEntorno: LeerVariable = (nombre) => Deno.env.get(nombre);

/** La configuración de proveedores no es válida. Trae un problema por línea. */
export class ErrorDeConfiguracion extends Error {
  constructor(readonly problemas: string[]) {
    super(`Configuración de proveedores inválida: ${problemas.join("; ")}`);
    this.name = "ErrorDeConfiguracion";
  }
}

/** Entorno y proveedor elegido de cada integración. */
export interface Configuracion {
  entorno: Entorno;
  proveedores: Readonly<Record<Integracion, string>>;
}

/**
 * Qué implementación hay para cada nombre de proveedor. La simulada es obligatoria
 * (FR-004). Los nombres van en minúsculas: `alpaca`, `deepseek`, `fcm`…
 */
export type Implementaciones<T> =
  & { simulado: () => T }
  & Readonly<Record<string, () => T>>;

/** Quita espacios y pasa a minúsculas; una variable vacía cuenta como no definida. */
function normalizar(valor: string | undefined): string | undefined {
  return valor?.trim().toLowerCase() || undefined;
}

function esEntorno(valor: string): valor is Entorno {
  return (ENTORNOS as readonly string[]).includes(valor);
}

/**
 * Lee `ENTORNO` y los seis `PROVEEDOR_*`, y lanza ErrorDeConfiguracion si
 * `ENTORNO=mvp` y alguno es simulado (CB-91) o si `ENTORNO` no es un entorno conocido.
 *
 * Por defecto el entorno es `local` y cada proveedor es `simulado` (docs/10 §9: "Local y
 * CI: todo simulado por defecto"). En `mvp` eso hace que una variable olvidada falle en
 * vez de funcionar con un simulado.
 *
 * Los valores no se copian en los mensajes de error: así una llave pegada por error en
 * una de estas variables no llega a los registros (CLAUDE.md, invariantes).
 */
export function leerConfiguracion(
  leer: LeerVariable = leerDelEntorno,
): Configuracion {
  const problemas: string[] = [];

  const entornoLeido = normalizar(leer("ENTORNO")) ?? ENTORNO_POR_DEFECTO;
  if (!esEntorno(entornoLeido)) {
    problemas.push(`ENTORNO no es uno de: ${ENTORNOS.join(", ")}`);
  }
  const entorno = esEntorno(entornoLeido) ? entornoLeido : ENTORNO_POR_DEFECTO;

  const proveedores = {} as Record<Integracion, string>;
  for (const integracion of INTEGRACIONES) {
    const variable = VARIABLE_DE_PROVEEDOR[integracion];
    proveedores[integracion] = normalizar(leer(variable)) ?? SIMULADO;
  }

  if (entornoLeido === "mvp") {
    const simulados = INTEGRACIONES
      .filter((integracion) => proveedores[integracion] === SIMULADO)
      .map((integracion) => VARIABLE_DE_PROVEEDOR[integracion]);
    if (simulados.length > 0) {
      problemas.push(
        `ENTORNO=mvp no admite proveedores simulados: ${simulados.join(", ")}`,
      );
    }
  }

  if (problemas.length > 0) throw new ErrorDeConfiguracion(problemas);
  return { entorno, proveedores };
}

/**
 * Devuelve la implementación de una integración según su variable `PROVEEDOR_*`.
 *
 * Primero valida toda la configuración (`leerConfiguracion`), así que con
 * `ENTORNO=mvp` se niega aunque el simulado sea el de otra integración. Solo se crea
 * la implementación elegida: la real no se construye (ni pide sus llaves) cuando el
 * proveedor es el simulado, y al revés.
 *
 * @example
 * const broker = elegirProveedor<Broker>("broker", {
 *   simulado: () => new BrokerSimulado(),
 *   alpaca: () => new BrokerAlpaca(),
 * });
 */
export function elegirProveedor<T>(
  integracion: Integracion,
  implementaciones: Implementaciones<T>,
  leer: LeerVariable = leerDelEntorno,
): T {
  const nombre = leerConfiguracion(leer).proveedores[integracion];
  // hasOwn: un valor como "constructor" o "__proto__" no es un proveedor.
  const crear = Object.hasOwn(implementaciones, nombre)
    ? implementaciones[nombre]
    : undefined;
  if (!crear) {
    throw new ErrorDeConfiguracion([
      `${VARIABLE_DE_PROVEEDOR[integracion]} no es uno de: ${
        Object.keys(implementaciones).join(", ")
      }`,
    ]);
  }
  return crear();
}
