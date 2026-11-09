-- HU-019 · RPC mi_cupo(): lo que el Usuario ve de su cupo.
-- Fuentes: docs/06 §6, docs/02 §2 (disponible, patrimonio) y §13 (cifras de la app), RN-06, RN-20,
-- docs/12 CB-80 (fondo sin capital), docs/03 PM-10.
--
-- Devuelve una fila con el cupo de quien llama; ninguna si no tiene cupo abierto. Solo el Usuario
-- (NO_AUTORIZADO para analista y administrador, que no tienen cupo). Un Usuario solo puede leer su
-- propia fila: la función no recibe parámetros, lee auth.uid().
--
-- Lo que todavía no existe se entrega de forma honesta, no inventada:
--  * patrimonio = efectivo + invertido (el invertido está a costo): las posiciones y los precios que
--    lo valoran al precio de mercado llegan con HU-091. Mientras no hay posiciones coincide.
--  * resultado_realizado: sale del libro (suma de las ventas del cupo, docs/02 §13).
--  * resultado_no_realizado: 0 hasta que existan las posiciones (RN-06: se calcula al vuelo).
--  * rendimiento: nulo hasta que HU-021 tome las fotos diarias del TWR.
-- fondo_con_capital: hay al menos un aporte en el libro (CB-80, RN-11).

create function public.mi_cupo()
returns table (
  subcuenta_id             uuid,
  efectivo                 numeric,
  retenido                 numeric,
  disponible               numeric,
  invertido                numeric,
  patrimonio               numeric,
  resultado_realizado      numeric,
  resultado_no_realizado   numeric,
  rendimiento              numeric,
  fondo_con_capital        boolean,
  version                  int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_rol public.rol_app := private.rol_actual();
begin
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'usuario' then
    raise exception 'NO_AUTORIZADO';
  end if;

  return query
  select s.id, s.efectivo, s.retenido, s.efectivo - s.retenido, s.invertido,
         s.efectivo + s.invertido,
         coalesce((
           select -sum(r.monto)
             from public.movimientos m
             join public.asientos r on r.movimiento_id = m.id
             join public.subcuentas rs on rs.id = r.subcuenta_id and rs.tipo = 'resultados'
            where m.tipo = 'venta'
              and exists (select 1 from public.asientos c where c.movimiento_id = m.id and c.subcuenta_id = s.id)
         ), 0)::numeric,
         0::numeric,
         null::numeric,
         exists (select 1 from public.movimientos m where m.tipo = 'aporte'),
         s.version
    from public.subcuentas s
   where s.tipo = 'cupo' and s.usuario_id = (select auth.uid()) and s.estado = 'abierta';
end;
$$;

comment on function public.mi_cupo() is
  'Usuario: su cupo (efectivo, retenido, disponible, patrimonio, resultado realizado y no realizado, rendimiento) y si el fondo ya tiene capital. Sin parámetros: solo lee el suyo (RN-20). docs/06 §6.';
revoke all on function public.mi_cupo() from public, anon;
grant execute on function public.mi_cupo() to authenticated;
