// Manejador HTTP de calendario-mercado (docs/05 §6): solo acepta el secreto interno, que envía
// el trabajo diario `calendario` de pg_cron o una persona que lo llame a mano.
//
// Cuatro pasos independientes (HU-027 y HU-026): sincronizar el calendario del broker, contrastar
// su reloj, sincronizar los atributos de los activos y cargar la historia de barras diarias. Si
// uno falla por el proveedor, los demás igual corren: el calendario y los activos usan la API de
// trading de Alpaca y las barras la de datos, y que una caiga no impide lo que la otra puede hacer.
//
// Respuestas:
//   200  los cuatro pasos: ResultadoDeCarga en la raíz (HU-026) más `calendario`, `reloj`, `activos`
//   401  SESION_INVALIDA   sin secreto ni sesión, o con un JWT (esta función no acepta personas)
//   403  NO_AUTORIZADO     secreto incorrecto
//   405  otro método que POST
//   502  INTEGRACION_CAIDA un proveedor falló; trae el resultado de cada paso (`error` en el que falló)
//   500  cualquier otro fallo (base de datos, configuración); sin detalles internos

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import { registrarSalud } from "../_shared/salud.ts";
import type { Broker } from "../_shared/broker/interfaz.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import {
  cargarHistoria,
  ErrorDeCarga,
  PRESUPUESTO_DE_TIEMPO_MS,
  type ResultadoDeCarga,
} from "./carga_historica.ts";
import {
  contrastarReloj,
  sincronizarActivos,
  sincronizarCalendario,
} from "./sincronizacion.ts";

export interface DependenciasDeManejador {
  mercado: ProveedorDeMercado;
  broker: Broker;
  /** Abre una conexión a la base; el manejador la cierra siempre al terminar. */
  abrirBd: () => Bd;
  /** SECRETO_INTERNO. Por defecto se lee del entorno en cada llamada. */
  secreto?: string;
  /** Milisegundos actuales para el presupuesto de tiempo; las pruebas lo reemplazan. */
  reloj?: () => number;
}

/** Resultado de un paso: lo que entregó o el error del proveedor que lo detuvo. */
type Paso<T> = T | { error: string };

/** Corre un paso; un error del proveedor se vuelve parte de la respuesta y lo demás se propaga. */
async function correr<T>(
  paso: () => Promise<T>,
  fallos: string[],
): Promise<Paso<T>> {
  try {
    return await paso();
  } catch (error) {
    if (!(error instanceof ErrorDeProveedor)) throw error;
    fallos.push(error.message);
    return { error: error.message };
  }
}

/** Esta función no acepta personas: ningún JWT identifica a nadie. */
const SIN_PERSONAS: Identidad = {
  usuarioDelToken: () => Promise.resolve(null),
  rolDe: () => Promise.resolve(null),
};

function responder(
  estado: number,
  cuerpo: unknown,
  cabeceras: HeadersInit = {},
): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "Content-Type": "application/json", ...cabeceras },
  });
}

export function crearManejador(
  dependencias: DependenciasDeManejador,
): (peticion: Request) => Promise<Response> {
  return async (peticion) => {
    if (peticion.method !== "POST") {
      return responder(405, { error: "método no permitido" }, {
        Allow: "POST",
      });
    }

    try {
      await autenticar(
        peticion,
        { aceptaInterno: true, roles: [] },
        SIN_PERSONAS,
        dependencias.secreto,
      );
    } catch (error) {
      if (error instanceof ErrorDeAcceso) return respuestaDeAcceso(error);
      console.error("calendario-mercado: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    let bd: Bd | undefined;
    try {
      const reloj = dependencias.reloj ?? Date.now;
      const inicio = reloj();
      bd = dependencias.abrirBd();

      const [{ ahora }] = await bd.llamar<{ ahora: Date }>("ahora");
      if (!(ahora instanceof Date) || Number.isNaN(ahora.getTime())) {
        throw new Error("private.ahora() no devolvió una hora válida");
      }
      const base = { bd, broker: dependencias.broker, ahora };
      const fallos: string[] = [];

      const calendario = await correr(
        () => sincronizarCalendario(base),
        fallos,
      );
      const relojDelBroker = await correr(() => contrastarReloj(base), fallos);
      const activos = await correr(() => sincronizarActivos(base), fallos);
      // Calendario, reloj y activos son del broker (HU-035): un fallo de cualquiera cuenta como fallo.
      await registrarSalud(
        bd,
        "alpaca_trading",
        fallos.length === 0,
        fallos[0],
      );
      const fallosDelBroker = fallos.length;

      // La historia de barras recibe lo que queda del presupuesto de tiempo de la función.
      let historia: Partial<ResultadoDeCarga>;
      try {
        historia = await cargarHistoria({
          bd,
          mercado: dependencias.mercado,
          reloj,
          presupuestoMs: Math.max(
            0,
            PRESUPUESTO_DE_TIEMPO_MS - (reloj() - inicio),
          ),
        });
      } catch (error) {
        if (!(error instanceof ErrorDeCarga)) throw error;
        fallos.push(error.message);
        historia = error.parcial;
      }
      // La historia de barras viene del proveedor de datos de mercado.
      await registrarSalud(
        bd,
        "alpaca_datos",
        fallos.length === fallosDelBroker,
        fallos[fallosDelBroker],
      );

      const cuerpo = {
        ...historia,
        calendario,
        reloj: relojDelBroker,
        activos,
      };
      if (fallos.length > 0) {
        console.error(
          `calendario-mercado: un proveedor falló: ${fallos.join("; ")}`,
        );
        return responder(502, {
          codigo: "INTEGRACION_CAIDA",
          detalle: fallos.join("; "),
          ...cuerpo,
        });
      }
      console.log(
        `calendario-mercado: ${historia.simbolos_consultados} símbolos de historia, ` +
          `${historia.barras_nuevas} barras nuevas, ${historia.pendientes?.length} pendientes`,
      );
      return responder(200, cuerpo);
    } catch (error) {
      // Los mensajes de ErrorDeBd ya van sin URL ni contraseña (_shared/bd.ts).
      console.error(
        `calendario-mercado: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error(
          "calendario-mercado: no se pudo cerrar la conexión a la base",
        );
      }
    }
  };
}
