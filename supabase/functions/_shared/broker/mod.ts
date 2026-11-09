// Elige el broker según PROVEEDOR_BROKER (docs/10 §9, _shared/proveedores.ts).
//
//   PROVEEDOR_BROKER=simulado (o sin definir)  → BrokerSimulado, con el reloj de RELOJ_SIMULADO
//   PROVEEDOR_BROKER=alpaca                    → BrokerAlpaca, con ALPACA_KEY_ID,
//                                                ALPACA_SECRET_KEY y ALPACA_TRADING_URL
//
// EFECTIVO_SIMULADO (USD, por defecto 100000) es el efectivo de la cuenta del broker simulado.
// RELOJ_SIMULADO solo cambia al broker simulado: `calendario` (por defecto), `siempre_abierto`,
// `cerrado` o `cierre_en_10_min`. Otro valor es un error de configuración.
//
// Con ENTORNO=mvp, `elegirProveedor` se niega a usar cualquier proveedor simulado (CB-91).
// Cada función debe llamar a esta función al cargar el módulo, fuera del manejador de
// peticiones: así, una configuración inválida impide que la función arranque.

import {
  elegirProveedor,
  ErrorDeConfiguracion,
  type LeerVariable,
} from "../proveedores.ts";
import { BrokerAlpaca } from "./alpaca.ts";
import type { Broker } from "./interfaz.ts";
import {
  BrokerSimulado,
  type ModoDeReloj,
  MODOS_DE_RELOJ,
} from "./simulado.ts";

export type {
  ActivoDelBroker,
  Broker,
  ConsultaDeCalendario,
  CuentaDelBroker,
  DiaDeCalendario,
  RelojDelBroker,
} from "./interfaz.ts";

/** URL de la API de trading paper de Alpaca si ALPACA_TRADING_URL no está definida (docs/10 §1). */
export const URL_DE_TRADING_POR_DEFECTO = "https://paper-api.alpaca.markets";

function efectivoSimulado(leer: LeerVariable): number | undefined {
  const texto = leer("EFECTIVO_SIMULADO")?.trim();
  if (!texto) return undefined;
  const valor = Number(texto);
  if (!Number.isFinite(valor) || valor < 0) {
    throw new ErrorDeConfiguracion([
      "EFECTIVO_SIMULADO debe ser un número no negativo",
    ]);
  }
  return valor;
}

function modoDeReloj(leer: LeerVariable): ModoDeReloj {
  const valor = leer("RELOJ_SIMULADO")?.trim().toLowerCase() || "calendario";
  if (!(MODOS_DE_RELOJ as readonly string[]).includes(valor)) {
    throw new ErrorDeConfiguracion([
      `RELOJ_SIMULADO no es uno de: ${MODOS_DE_RELOJ.join(", ")}`,
    ]);
  }
  return valor as ModoDeReloj;
}

export function crearBroker(
  leer: LeerVariable = (nombre) => Deno.env.get(nombre),
): Broker {
  return elegirProveedor<Broker>("broker", {
    simulado: () =>
      new BrokerSimulado({
        modo: modoDeReloj(leer),
        efectivo: efectivoSimulado(leer),
      }),
    alpaca: () =>
      new BrokerAlpaca({
        urlTrading: leer("ALPACA_TRADING_URL")?.trim() ||
          URL_DE_TRADING_POR_DEFECTO,
        keyId: leer("ALPACA_KEY_ID")?.trim() ?? "",
        secretKey: leer("ALPACA_SECRET_KEY")?.trim() ?? "",
      }),
  }, leer);
}
