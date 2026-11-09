// Manejador HTTP de ejecutor-ordenes (docs/05 §6): solo acepta el secreto interno, que envía el trabajo
// `barrer_ejecutor` de pg_cron (cada 10 s mientras la cola `ordenes_por_enviar` tenga mensajes) o una
// persona que lo llame a mano. No acepta JWT de personas (CA-7).
//
// Una pasada (HU-073): lee mensajes de la cola y, por cada orden,
//   1. `tomar_orden_para_envio` la bloquea y revalida (motor de políticas y banda de precio);
//   2. la envía al broker con `client_order_id` = id de la orden (idempotente);
//   3. cierra el envío con `registrar_respuesta_envio` o `registrar_error_envio` (docs/10 §10);
//   4. confirma el mensaje. Si algo queda en duda, no lo confirma: reaparece a los 60 s y la siguiente
//      pasada consulta al broker por `client_order_id` antes de enviar otra vez. Nunca se envía dos veces.
//
// Respuestas:
//   200  pasada hecha: { ordenes: [{ orden_id, resultado }] }
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
import {
  type Broker,
  envioIncierto,
  type OrdenAEnviar,
  type OrdenDelBroker,
  OrdenInvalida,
  OrdenRechazada,
} from "../_shared/broker/mod.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";
import { registrarSalud } from "../_shared/salud.ts";

export interface DependenciasDeManejador {
  broker: Broker;
  /** Abre una conexión a la base; el manejador la cierra siempre al terminar. */
  abrirBd: () => Bd;
  /** SECRETO_INTERNO. Por defecto se lee del entorno en cada llamada. */
  secreto?: string;
  /** Mensajes que se leen de la cola en cada pasada. */
  porPasada?: number;
}

/** Esta función no acepta personas: ningún JWT identifica a nadie. */
const SIN_PERSONAS: Identidad = {
  usuarioDelToken: () => Promise.resolve(null),
  rolDe: () => Promise.resolve(null),
};

const MENSAJES_POR_PASADA = 10;

/** Qué pasó con una orden en esta pasada. */
export type ResultadoDeOrden =
  | "aceptada"
  | "rechazada"
  | "error_envio"
  | "desconocida"
  | "fallida_en_revalidacion"
  | "ya_resuelta"
  | "pendiente";

interface Mensaje {
  mensaje_id: number | string;
  orden_id: string;
  lecturas: number;
}

/** Lo que `tomar_orden_para_envio` devuelve de la orden que hay que enviar. */
interface DatosDeOrden {
  id: string;
  estado: "creada" | "enviada" | "desconocida";
  simbolo: string;
  lado: "compra" | "venta";
  clase: "simple" | "bracket";
  cantidad: number;
  precio_limite: number;
  bracket_stop_precio: number | null;
  bracket_objetivo_precio: number | null;
}

interface Toma {
  resultado: "enviar" | "consultar" | "fallida" | "ya_resuelta";
  orden?: DatosDeOrden;
  reglas?: string[];
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
    patas: orden.patas.map((p) => ({
      id_broker: p.idBroker,
      tipo: p.tipo,
      estado: p.estado,
    })),
  };
}

function aOrdenAEnviar(datos: DatosDeOrden): OrdenAEnviar {
  const orden: OrdenAEnviar = {
    idCliente: datos.id,
    simbolo: datos.simbolo,
    lado: datos.lado,
    cantidad: Number(datos.cantidad),
    precioLimite: Number(datos.precio_limite),
  };
  if (datos.clase === "bracket" && datos.lado === "compra") {
    orden.proteccion = {
      stopLoss: Number(datos.bracket_stop_precio),
      objetivo: Number(datos.bracket_objetivo_precio),
    };
  }
  return orden;
}

async function procesar(
  bd: Bd,
  broker: Broker,
  mensaje: Mensaje,
): Promise<ResultadoDeOrden> {
  const id = mensaje.orden_id;
  const confirmar = () =>
    bd.llamar("confirmar_orden_por_enviar", [Number(mensaje.mensaje_id)]);

  const [fila] = await bd.llamar<Record<string, unknown>>(
    "tomar_orden_para_envio",
    [id],
  );
  const toma = Object.values(fila ?? {})[0] as Toma | undefined;
  if (!toma) throw new Error("tomar_orden_para_envio no devolvió nada");

  if (toma.resultado === "ya_resuelta") {
    await confirmar();
    return "ya_resuelta";
  }
  if (toma.resultado === "fallida") {
    // La revalidación falló (mercado cerrado, banda, interruptor, salud…): la orden ya quedó en error_envio.
    await confirmar();
    return "fallida_en_revalidacion";
  }
  const datos = toma.orden;
  if (!datos) throw new Error("tomar_orden_para_envio no devolvió la orden");

  const aceptar = async (orden: OrdenDelBroker): Promise<ResultadoDeOrden> => {
    await bd.llamar("registrar_respuesta_envio", [
      id,
      orden.idBroker,
      "aceptada",
      orden.estadoBroker,
      detalleDeOrden(orden),
    ]);
    await confirmar();
    return "aceptada";
  };

  // Un envío anterior no cerró (CB-33): se pregunta al broker por client_order_id antes de enviar.
  if (toma.resultado === "consultar") {
    let existente: OrdenDelBroker | null;
    try {
      existente = await broker.consultarOrden({ idCliente: id });
    } catch (error) {
      if (!(error instanceof ErrorDeProveedor)) throw error;
      await registrarSalud(bd, "alpaca_trading", false, error);
      return "pendiente"; // el mensaje reaparece y se vuelve a consultar
    }
    await registrarSalud(bd, "alpaca_trading", true);
    if (existente) return await aceptar(existente);
    if (datos.estado === "desconocida") {
      await bd.llamar("registrar_error_envio", [
        id,
        "error_envio",
        "NO_EXISTE_EN_BROKER",
        { consulta: "client_order_id", existe: false },
      ]);
      await confirmar();
      return "error_envio";
    }
    // Estaba `enviada` y el broker no la tiene: el envío anterior no llegó. Es seguro enviarla
    // (client_order_id es único en el broker).
  }

  let orden: OrdenDelBroker;
  try {
    orden = await broker.enviarOrden(aOrdenAEnviar(datos));
  } catch (error) {
    if (error instanceof OrdenInvalida) {
      await bd.llamar("registrar_error_envio", [
        id,
        "error_envio",
        "ORDEN_NO_SOPORTADA",
        { detalle: error.message },
      ]);
      await confirmar();
      return "error_envio";
    }
    if (error instanceof OrdenRechazada) {
      // El broker respondió: la integración está bien aunque haya rechazado la orden.
      await registrarSalud(bd, "alpaca_trading", true);
      const porFondos = error.motivo === "fondos_insuficientes";
      await bd.llamar("registrar_error_envio", [
        id,
        porFondos ? "rechazada" : "error_envio",
        porFondos ? "FONDOS_INSUFICIENTES" : "PARAMETROS_INVALIDOS",
        { estado_http: error.estado ?? null },
      ]);
      await confirmar();
      return porFondos ? "rechazada" : "error_envio";
    }
    if (envioIncierto(error)) {
      // Sin respuesta o 5xx: la orden puede existir. Queda `desconocida` y se consulta por client_order_id.
      await registrarSalud(bd, "alpaca_trading", false, error);
      await bd.llamar("registrar_error_envio", [
        id,
        "desconocida",
        "SIN_RESPUESTA",
        { estado_http: (error as ErrorDeProveedor).estado ?? null },
      ]);
      let existente: OrdenDelBroker | null;
      try {
        existente = await broker.consultarOrden({ idCliente: id });
      } catch {
        return "desconocida"; // el mensaje reaparece; la siguiente pasada la consulta
      }
      if (existente) return await aceptar(existente);
      await bd.llamar("registrar_error_envio", [
        id,
        "error_envio",
        "NO_EXISTE_EN_BROKER",
        { consulta: "client_order_id", existe: false },
      ]);
      await confirmar();
      return "error_envio";
    }
    if (error instanceof ErrorDeProveedor) {
      // 429 u otro error sin orden creada: no se confirma el mensaje; reaparece y la siguiente pasada
      // consulta al broker antes de reintentar (docs/10 §10: reintento con espera, la cola lo garantiza).
      console.error(
        `ejecutor-ordenes: el broker no tomó la orden: ${error.message}`,
      );
      return "pendiente";
    }
    throw error;
  }

  await registrarSalud(bd, "alpaca_trading", true);
  return await aceptar(orden);
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
      console.error("ejecutor-ordenes: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    let bd: Bd | undefined;
    try {
      bd = dependencias.abrirBd();
      const mensajes = await bd.llamar<Mensaje>("leer_ordenes_por_enviar", [
        dependencias.porPasada ?? MENSAJES_POR_PASADA,
      ]);
      const ordenes: { orden_id: string; resultado: ResultadoDeOrden }[] = [];
      for (const mensaje of mensajes) {
        try {
          ordenes.push({
            orden_id: mensaje.orden_id,
            resultado: await procesar(bd, dependencias.broker, mensaje),
          });
        } catch (error) {
          // Una orden con problemas no frena a las demás; su mensaje reaparece y, tras 5 lecturas,
          // se archiva y la orden queda en error_envio (CB-68).
          console.error(
            `ejecutor-ordenes: fallo con la orden ${mensaje.orden_id}: ${
              error instanceof Error ? error.message : error
            }`,
          );
          ordenes.push({ orden_id: mensaje.orden_id, resultado: "pendiente" });
        }
      }
      console.log(`ejecutor-ordenes: ${ordenes.length} orden(es) procesadas`);
      return responder(200, { ordenes });
    } catch (error) {
      console.error(
        `ejecutor-ordenes: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error(
          "ejecutor-ordenes: no se pudo cerrar la conexión a la base",
        );
      }
    }
  };
}
