# Contrato: `_shared/bd.ts` (D-66)

Única puerta de las Edge Functions a Postgres. Es el **único** archivo de `supabase/functions` que importa el cliente de Postgres (`npm:postgres`); lo vigilan `scripts/verificar.sh` y el trabajo `arquitectura` de CI.

```ts
export interface Bd {
  /** Ejecuta private.<funcion>(...argumentos) y devuelve sus filas. */
  llamar<T = Record<string, unknown>>(
    funcion: string,
    argumentos?: readonly Argumento[],
  ): Promise<T[]>;
  /** Cierra la conexión. */
  cerrar(): Promise<void>;
}

export type Argumento =
  | string | number | boolean | null | Date
  | readonly unknown[] | Record<string, unknown>; // objetos y arreglos viajan como JSON (jsonb)

export function crearBd(opciones?: { url?: string }): Bd;   // url: SUPABASE_DB_URL por defecto
export class ErrorDeBd extends Error {}                     // nombre inválido, sin URL, fallo de la base
```

## Reglas

1. `funcion` debe cumplir `^[a-z][a-z0-9_]*$` y no puede llevar esquema. Si no, se lanza `ErrorDeBd` **antes** de abrir la conexión.
2. La consulta es siempre `select * from private."<funcion>"($1, …, $n)` con los argumentos enlazados. No se arma SQL con los valores.
3. Sin `SUPABASE_DB_URL` ni `url`, `crearBd` lanza `ErrorDeBd` con un mensaje que nombra la variable.
4. Los mensajes de error **nunca** incluyen la URL de conexión, el usuario ni la contraseña.
5. Una conexión por instancia (`max: 1`), `prepare: false` (compatible con el *pooler*), `connect_timeout` y `idle_timeout` cortos.

## Pruebas (`deno test`)

- Nombres válidos pasan y generan `select * from private."nombre"($1, $2)`; nombres con `.`, `"`, `;`, espacios, mayúsculas o vacíos se rechazan sin llamar al ejecutor.
- Los argumentos llegan enlazados y en orden; un objeto se serializa a JSON.
- Sin URL: error que nombra `SUPABASE_DB_URL`.
- Un fallo de conexión no filtra la URL ni la contraseña.
