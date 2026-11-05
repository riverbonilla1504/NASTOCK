// Validación de datos con zod (docs/05 §6). Todo lo que llega de afuera
// (peticiones de la app y respuestas de los proveedores) se valida antes de usarse
// (docs/11 §3, "validación de todo lo externo").

import { z } from "zod";

export { z };

/** Los datos no cumplen el esquema. Trae un problema por campo. */
export class ErrorDeDatos extends Error {
  constructor(readonly problemas: string[]) {
    super(`Datos inválidos: ${problemas.join("; ")}`);
    this.name = "ErrorDeDatos";
  }
}

/** Devuelve los datos ya tipados o lanza ErrorDeDatos. */
export function validar<T>(esquema: z.ZodType<T>, datos: unknown): T {
  const resultado = esquema.safeParse(datos);
  if (!resultado.success) {
    throw new ErrorDeDatos(
      resultado.error.issues.map((problema) =>
        `${problema.path.join(".") || "(raíz)"}: ${problema.message}`
      ),
    );
  }
  return resultado.data;
}

/** Identificador uuid, el de casi todas las tablas (docs/06 §1). */
export const uuid = z.string().uuid();
