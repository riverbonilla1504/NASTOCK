// Manejador HTTP de calendario-mercado (docs/05 §6): solo acepta el secreto interno, que envía
// el trabajo diario de pg_cron (HU-027) o una persona que lo llame a mano. Esta historia
// (HU-026) entrega solo la carga inicial de barras históricas; el calendario, el reloj y los
// atributos de los activos son de HU-027.
//
// Respuestas:
//   200  carga hecha (o nada que cargar): ResultadoDeCarga
//   401  SESION_INVALIDA   sin secreto ni sesión, o con un JWT (esta función no acepta personas)
//   403  NO_AUTORIZADO     secreto incorrecto
//   405  otro método que POST
//   502  INTEGRACION_CAIDA el proveedor de mercado falló; trae lo ya guardado y los pendientes
//   500  cualquier otro fallo (base de datos, configuración); sin detalles internos

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import type { ProveedorDeMercado } from "../_shared/mercado/interfaz.ts";
import { cargarHistoria, ErrorDeCarga } from "./carga_historica.ts";

export interface DependenciasDeManejador {
  mercado: ProveedorDeMercado;
  /** Abre una conexión a la base; el manejador la cierra siempre al terminar. */
  abrirBd: () => Bd;
  /** SECRETO_INTERNO. Por defecto se lee del entorno en cada llamada. */
  secreto?: string;
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
      bd = dependencias.abrirBd();
      const resultado = await cargarHistoria({
        bd,
        mercado: dependencias.mercado,
      });
      console.log(
        `calendario-mercado: ${resultado.simbolos_consultados} símbolos, ` +
          `${resultado.barras_nuevas} barras nuevas, ${resultado.pendientes.length} pendientes`,
      );
      return responder(200, resultado);
    } catch (error) {
      if (error instanceof ErrorDeCarga) {
        console.error(
          `calendario-mercado: el proveedor de mercado falló: ${error.message}`,
        );
        return responder(502, {
          codigo: "INTEGRACION_CAIDA",
          detalle: error.message,
          ...error.parcial,
        });
      }
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
