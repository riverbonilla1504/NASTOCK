// Órdenes del broker simulado (docs/10 §9): acepta, llena con el siguiente precio si cumple el
// límite, ejecuta las patas del bracket cuando el precio las cruza y permite forzar escenarios.
//
// El tiempo del simulado avanza con `avanzar(precios)`: cada llamada es un "siguiente precio".
// Una orden recién enviada queda `aceptada`; se llena en el siguiente `avanzar` si el precio
// cumple su límite (nunca a un precio peor que el aprobado, RN-24). Las patas de un bracket se
// evalúan desde el `avanzar` siguiente al del llenado de la entrada.
//
// Escenarios forzables (docs/10 §9; en local los elige `pruebas.elegir_escenario('broker', …)`):
//   normal           comportamiento por defecto
//   llenado_parcial  la entrada se llena a la mitad (cantidad ÷ 2, redondeada hacia abajo) y el
//                    resto no se llena nunca; con 1 sola acción se llena completa
//   rechazo          `enviarOrden` falla con `OrdenRechazada` (fondos insuficientes)
//   sin_respuesta    `enviarOrden` registra la orden pero falla como si el broker no respondiera:
//                    solo se puede recuperar consultándola por `idCliente` (docs/10 §10)
//   halt             la orden se acepta pero nunca se llena (activo suspendido)
//
// El estado vive en memoria de la instancia: dura lo que dure la función que lo usa.

import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import {
  type EstadoDeOrdenBroker,
  type OrdenAEnviar,
  type OrdenDelBroker,
  OrdenRechazada,
  type PataDeOrden,
  type PosicionDelBroker,
  type ReferenciaDeOrden,
  type ResultadoDeCancelacion,
  validarOrden,
} from "./interfaz.ts";

export const ESCENARIOS_DE_ORDEN = [
  "normal",
  "llenado_parcial",
  "rechazo",
  "sin_respuesta",
  "halt",
] as const;

export type EscenarioDeOrden = (typeof ESCENARIOS_DE_ORDEN)[number];

export function esEscenarioDeOrden(valor: string): valor is EscenarioDeOrden {
  return (ESCENARIOS_DE_ORDEN as readonly string[]).includes(valor);
}

const ABIERTAS: readonly EstadoDeOrdenBroker[] = ["aceptada", "parcial"];

function promedio(
  cantidadA: number,
  precioA: number | null,
  cantidadB: number,
  precioB: number,
): number {
  if (precioA === null || cantidadA === 0) return precioB;
  const total = cantidadA + cantidadB;
  return Math.round(
    ((cantidadA * precioA + cantidadB * precioB) / total) * 1e6,
  ) / 1e6;
}

/** Estado crudo que Alpaca usaría para cada estado nuestro (docs/08 §2.1). */
const ESTADO_CRUDO: Record<EstadoDeOrdenBroker, string> = {
  aceptada: "new",
  parcial: "partially_filled",
  llena: "filled",
  cancelada: "canceled",
  expirada: "expired",
  rechazada: "rejected",
};

/** Copia de una orden para entregarla: modificarla no cambia al broker. */
function copia(orden: OrdenDelBroker): OrdenDelBroker {
  const clon = structuredClone(orden);
  clon.estadoBroker = ESTADO_CRUDO[clon.estado];
  return clon;
}

export class OrdenesSimuladas {
  escenario: EscenarioDeOrden;
  #secuencia = 0;
  readonly #ordenes = new Map<string, OrdenDelBroker>();
  readonly #precios = new Map<string, number>();
  readonly #rechazaSimbolo: (simbolo: string) => string | null;

  /** `rechazaSimbolo` devuelve el motivo si el broker no deja operar ese símbolo. */
  constructor(
    escenario: EscenarioDeOrden,
    rechazaSimbolo: (simbolo: string) => string | null,
  ) {
    this.escenario = escenario;
    this.#rechazaSimbolo = rechazaSimbolo;
  }

  enviar(orden: OrdenAEnviar): OrdenDelBroker {
    validarOrden(orden);
    if (this.escenario === "rechazo") {
      throw new OrdenRechazada(
        "fondos_insuficientes",
        "El broker simulado rechazó la orden por fondos (403)",
        403,
      );
    }
    const motivo = this.#rechazaSimbolo(orden.simbolo);
    if (motivo) {
      throw new OrdenRechazada(
        "parametros_invalidos",
        `El broker simulado rechazó los parámetros de la orden (422): ${motivo}`,
        422,
      );
    }
    for (const existente of this.#ordenes.values()) {
      if (existente.idCliente === orden.idCliente) {
        throw new OrdenRechazada(
          "parametros_invalidos",
          "El broker simulado rechazó los parámetros de la orden (422): idCliente repetido",
          422,
        );
      }
    }

    const id = `sim-${++this.#secuencia}`;
    const patas: PataDeOrden[] = orden.proteccion
      ? [
        {
          idBroker: `${id}-sl`,
          tipo: "stop_loss",
          precio: orden.proteccion.stopLoss,
          estado: "aceptada",
          cantidadLlenada: 0,
          precioPromedio: null,
        },
        {
          idBroker: `${id}-tp`,
          tipo: "objetivo",
          precio: orden.proteccion.objetivo,
          estado: "aceptada",
          cantidadLlenada: 0,
          precioPromedio: null,
        },
      ]
      : [];
    const creada: OrdenDelBroker = {
      idBroker: id,
      idCliente: orden.idCliente,
      simbolo: orden.simbolo,
      lado: orden.lado,
      cantidad: orden.cantidad,
      precioLimite: orden.precioLimite,
      estado: "aceptada",
      estadoBroker: "",
      cantidadLlenada: 0,
      precioPromedio: null,
      patas,
    };
    this.#ordenes.set(id, creada);
    if (this.escenario === "sin_respuesta") {
      throw new ErrorDeProveedor("El broker simulado no respondió a tiempo");
    }
    return copia(creada);
  }

  consultar(referencia: ReferenciaDeOrden): OrdenDelBroker | null {
    for (const orden of this.#ordenes.values()) {
      const coincide = "idBroker" in referencia
        ? orden.idBroker === referencia.idBroker
        : orden.idCliente === referencia.idCliente;
      if (coincide) return copia(orden);
    }
    return null;
  }

  cancelar(idBroker: string): ResultadoDeCancelacion {
    const orden = this.#ordenes.get(idBroker);
    if (orden) {
      if (!ABIERTAS.includes(orden.estado)) {
        // Un bracket ya lleno conserva sus patas vivas: cancelar la entrada no las toca.
        return "ya_cerrada";
      }
      orden.estado = "cancelada";
      // Política provisional de docs/10 §6 (Q-12): se cancelan las patas del bracket.
      for (const pata of orden.patas) {
        if (pata.estado === "aceptada") pata.estado = "cancelada";
      }
      return "cancelada";
    }
    for (const padre of this.#ordenes.values()) {
      const pata = padre.patas.find((p) => p.idBroker === idBroker);
      if (!pata) continue;
      if (pata.estado !== "aceptada") return "ya_cerrada";
      pata.estado = "cancelada";
      return "cancelada";
    }
    return "no_existe";
  }

  /** Fija los precios vigentes y procesa las órdenes vivas contra ellos. */
  avanzar(precios: Readonly<Record<string, number>>): void {
    for (const [simbolo, precio] of Object.entries(precios)) {
      if (Number.isFinite(precio) && precio > 0) {
        this.#precios.set(simbolo, precio);
      }
    }
    if (this.escenario === "halt") return;
    for (const orden of this.#ordenes.values()) {
      const precio = precios[orden.simbolo];
      if (precio === undefined || !(precio > 0)) continue;
      // Las patas esperan al siguiente precio después del llenado de la entrada.
      if (ABIERTAS.includes(orden.estado)) {
        if (this.#llenarEntrada(orden, precio)) continue;
      }
      this.#evaluarPatas(orden, precio);
    }
  }

  posiciones(): PosicionDelBroker[] {
    const netas = new Map<
      string,
      { cantidad: number; compradas: number; costo: number }
    >();
    const anotar = (
      simbolo: string,
      delta: number,
      precio: number | null,
    ) => {
      const p = netas.get(simbolo) ??
        { cantidad: 0, compradas: 0, costo: 0 };
      p.cantidad += delta;
      if (delta > 0 && precio !== null) {
        p.compradas += delta;
        p.costo += delta * precio;
      }
      netas.set(simbolo, p);
    };
    for (const orden of this.#ordenes.values()) {
      anotar(
        orden.simbolo,
        orden.lado === "compra"
          ? orden.cantidadLlenada
          : -orden.cantidadLlenada,
        orden.precioPromedio,
      );
      for (const pata of orden.patas) {
        anotar(orden.simbolo, -pata.cantidadLlenada, null);
      }
    }
    return [...netas.entries()]
      .filter(([, p]) => p.cantidad > 0)
      .map(([simbolo, p]) => ({
        simbolo,
        cantidad: p.cantidad,
        precioPromedioDeEntrada: p.compradas > 0 ? p.costo / p.compradas : 0,
        precioActual: this.#precios.get(simbolo) ?? null,
      }));
  }

  #llenarEntrada(orden: OrdenDelBroker, precio: number): boolean {
    const limite = orden.precioLimite ?? 0;
    const cumple = orden.lado === "compra"
      ? precio <= limite
      : precio >= limite;
    if (!cumple) return false;
    const faltante = orden.cantidad - orden.cantidadLlenada;
    let cantidad = faltante;
    if (this.escenario === "llenado_parcial") {
      if (orden.estado === "parcial") return false; // el resto no se llena nunca
      const mitad = Math.floor(orden.cantidad / 2);
      if (mitad > 0) cantidad = mitad;
    }
    orden.precioPromedio = promedio(
      orden.cantidadLlenada,
      orden.precioPromedio,
      cantidad,
      precio,
    );
    orden.cantidadLlenada += cantidad;
    orden.estado = orden.cantidadLlenada >= orden.cantidad
      ? "llena"
      : "parcial";
    return true;
  }

  #evaluarPatas(orden: OrdenDelBroker, precio: number): void {
    if (orden.cantidadLlenada === 0) return;
    for (const pata of orden.patas) {
      if (pata.estado !== "aceptada") continue;
      const cruzada = pata.tipo === "stop_loss"
        ? precio <= pata.precio
        : precio >= pata.precio;
      if (!cruzada) continue;
      pata.estado = "llena";
      pata.cantidadLlenada = orden.cantidadLlenada;
      pata.precioPromedio = precio;
      // Una pata llenada cancela a la otra (OCO).
      for (const otra of orden.patas) {
        if (otra !== pata && otra.estado === "aceptada") {
          otra.estado = "cancelada";
        }
      }
      return;
    }
  }
}
