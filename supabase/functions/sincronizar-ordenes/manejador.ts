// Manejador HTTP de sincronizar-ordenes (docs/05 §6): solo acepta el secreto interno, que envía el trabajo
// `sincronizar_ordenes` de pg_cron (cada 10 s mientras haya órdenes vivas) o una persona que lo llame a mano.
//
// Una pasada (HU-074, docs/10 §7):
//   1. Cancela en el broker las compras que superaron `ejecucion.minutos_max_llenado` sin llenarse (CB-35,
//      CB-39); lo ya llenado se conserva.
//   2. Por cada orden viva (aceptada, parcial o desconocida) consulta su estado al broker y se lo entrega a
//      `aplicar_llenado`, que aplica solo la diferencia (idempotente). Una desconocida se busca por
//      `client_order_id` (CB-33).
//
// Si el broker falla se registra su salud y se corta la pasada: la siguiente (10 s después) vuelve a intentar.
// El detalle por orden va en la respuesta; los fallos de base de una orden no frenan a las demás.
//
// Respuestas:
//   200  pasada hecha: { canceladas: [...], ordenes: [{ orden_id, resultado }] }
//   401  SESION_INVALIDA   sin secreto ni sesión, o con un JWT
//   403  NO_AUTORIZADO     secreto incorrecto
//   405  otro método que POST
//   500  fallo de la base o de configuración; sin detalles internos

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import type { Broker, OrdenDelBroker } from "../_shared/broker/mod.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";
import { registrarSalud } from "../_shared/salud.ts";

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

export type ResultadoDeSincronizacion =
  | "sincronizada"
  | "no_encontrada"
  | "error";

interface OrdenViva {
  orden_id: string;
  broker_order_id: string | null;
  estado: "aceptada" | "parcialmente_llenada" | "desconocida";
}

interface OrdenPorCancelar {
  orden_id: string;
  broker_order_id: string;
}

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

/** Lo que se guarda del broker en `ordenes_eventos.detalle`: solo datos ya validados, nunca llaves. */
function detalleDeOrden(orden: OrdenDelBroker): Record<string, unknown> {
  return {
    id_broker: orden.idBroker,
    estado: orden.estadoBroker,
    cantidad_llenada: orden.cantidadLlenada,
  };
}

async function sincronizar(
  bd: Bd,
  broker: Broker,
  viva: OrdenViva,
): Promise<ResultadoDeSincronizacion> {
  const id = viva.orden_id;
  const orden = await broker.consultarOrden(
    viva.broker_order_id
      ? { idBroker: viva.broker_order_id }
      : { idCliente: id },
  );
  // El broker no la conoce: una desconocida la resuelve el ejecutor (CB-33); las demás se ignoran.
  if (!orden) return "no_encontrada";

  if (viva.estado === "desconocida") {
    await bd.llamar("registrar_respuesta_envio", [
      id,
      orden.idBroker,
      "aceptada",
      orden.estadoBroker,
      detalleDeOrden(orden),
    ]);
  }
  await bd.llamar("aplicar_llenado", [
    id,
    orden.cantidadLlenada,
    orden.precioPromedio,
    orden.estadoBroker,
    0,
  ]);
  return "sincronizada";
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
      console.error("sincronizar-ordenes: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    const { broker } = dependencias;
    let bd: Bd | undefined;
    try {
      bd = dependencias.abrirBd();
      const canceladas: { orden_id: string; resultado: string }[] = [];
      const ordenes: {
        orden_id: string;
        resultado: ResultadoDeSincronizacion;
      }[] = [];
      let brokerCaido = false;

      // 1. Compras que superaron el tiempo máximo de llenado.
      const porCancelar = await bd.llamar<OrdenPorCancelar>(
        "ordenes_por_cancelar_por_tiempo",
      );
      for (const orden of porCancelar) {
        try {
          const resultado = await broker.cancelarOrden(orden.broker_order_id);
          canceladas.push({ orden_id: orden.orden_id, resultado });
        } catch (error) {
          if (!(error instanceof ErrorDeProveedor)) throw error;
          console.error(
            `sincronizar-ordenes: no se pudo cancelar ${orden.orden_id}: ${error.message}`,
          );
          await registrarSalud(bd, "alpaca_trading", false, error);
          brokerCaido = true;
          break;
        }
      }

      // 2. Estado de cada orden viva.
      if (!brokerCaido) {
        const vivas = await bd.llamar<OrdenViva>("ordenes_para_sincronizar");
        let huboRespuesta = false;
        for (const viva of vivas) {
          try {
            const resultado = await sincronizar(bd, broker, viva);
            huboRespuesta = true;
            ordenes.push({ orden_id: viva.orden_id, resultado });
          } catch (error) {
            if (error instanceof ErrorDeProveedor) {
              // El broker falló: se registra y se corta; la siguiente pasada reintenta.
              console.error(
                `sincronizar-ordenes: el broker falló: ${error.message}`,
              );
              await registrarSalud(bd, "alpaca_trading", false, error);
              brokerCaido = true;
              break;
            }
            // Un fallo de base con una orden no frena a las demás.
            console.error(
              `sincronizar-ordenes: fallo con la orden ${viva.orden_id}: ${
                error instanceof Error ? error.message : error
              }`,
            );
            ordenes.push({ orden_id: viva.orden_id, resultado: "error" });
          }
        }
        if (huboRespuesta) await registrarSalud(bd, "alpaca_trading", true);
      }

      console.log(
        `sincronizar-ordenes: ${ordenes.length} orden(es), ${canceladas.length} cancelada(s) por tiempo`,
      );
      return responder(200, { canceladas, ordenes });
    } catch (error) {
      console.error(
        `sincronizar-ordenes: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error(
          "sincronizar-ordenes: no se pudo cerrar la conexión a la base",
        );
      }
    }
  };
}
