// Manejador HTTP de conciliacion (docs/05 §6): solo acepta el secreto interno, que envía el trabajo
// `conciliacion` de pg_cron o una persona que lo llame a mano.
//
// Un solo paso (HU-015): leer el efectivo de la cuenta del broker y entregárselo a
// private.registrar_conciliacion, que decide el resultado y confirma los aportes que se cubren. La
// decisión vive en la base, en una transacción, para que el libro y el aporte cambien juntos.
//
// Respuestas:
//   200  conciliación registrada: { conciliacion: { id, resultado, accion_tomada, … } }
//   401  SESION_INVALIDA   sin secreto ni sesión, o con un JWT (esta función no acepta personas)
//   403  NO_AUTORIZADO     secreto incorrecto
//   405  otro método que POST
//   502  INTEGRACION_CAIDA el broker falló; no se registra nada
//   500  cualquier otro fallo (base de datos, configuración); sin detalles internos

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import type { Broker } from "../_shared/broker/interfaz.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";

export interface DependenciasDeManejador {
  broker: Broker;
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
      console.error("conciliacion: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    let bd: Bd | undefined;
    try {
      // Primero el broker: si cae, no se abre la base ni se registra nada.
      let efectivo: number;
      try {
        ({ efectivo } = await dependencias.broker.cuenta());
      } catch (error) {
        if (!(error instanceof ErrorDeProveedor)) throw error;
        console.error(`conciliacion: el broker falló: ${error.message}`);
        return responder(502, {
          codigo: "INTEGRACION_CAIDA",
          detalle: error.message,
        });
      }

      bd = dependencias.abrirBd();
      const [fila] = await bd.llamar<Record<string, unknown>>(
        "registrar_conciliacion",
        [efectivo],
      );
      console.log(
        `conciliacion: ${fila?.resultado}, acción ${fila?.accion_tomada}`,
      );
      return responder(200, { conciliacion: fila });
    } catch (error) {
      // Los mensajes de ErrorDeBd ya van sin URL ni contraseña (_shared/bd.ts).
      console.error(
        `conciliacion: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error("conciliacion: no se pudo cerrar la conexión a la base");
      }
    }
  };
}
