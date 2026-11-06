-- HU-026 · Funciones de private del universo y de las barras diarias.
-- Fuentes: docs/06 §5.2 (QQQ se ingiere siempre), §7 regla 3 y §8.2 (funciones internas),
-- docs/10 §12 (carga de dos años de barras diarias), D-66 (las Edge Functions solo ejecutan
-- funciones de private, por conexión directa).
--
-- Las llama calendario-mercado desde _shared/bd.ts. Ningún rol de la API puede ejecutarlas.

-- Los símbolos que se ingieren: los activos de la lista blanca de cualquier bolsillo, más QQQ
-- aunque no esté activo en ninguno (es la referencia del índice).
create function private.simbolos_del_universo()
returns table (simbolo text)
language sql
stable
security definer
set search_path = ''
as $$
  select s.simbolo
    from (
      select l.simbolo from public.lista_blanca l where l.activo
      union
      select 'QQQ'
    ) s
   order by s.simbolo
$$;

comment on function private.simbolos_del_universo() is
  'Símbolos activos de la lista blanca de cualquier bolsillo, más QQQ (docs/06 §5.2).';

revoke all on function private.simbolos_del_universo() from public, anon, authenticated;

-- Los del universo que aún no tienen la historia completa: ninguna barra diaria dentro de los
-- primeros 7 días de la ventana que empieza en p_desde (los 7 días cubren fines de semana y
-- feriados al comienzo). Un símbolo con menos de dos años de vida (una salida a bolsa reciente)
-- siempre cuenta como sin historia: pedirlo otra vez es inofensivo, no duplica.
create function private.simbolos_sin_historia(p_desde date)
returns table (simbolo text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_desde is null then
    raise exception 'simbolos_sin_historia: desde es obligatorio';
  end if;

  return query
    select u.simbolo
      from private.simbolos_del_universo() u
     where not exists (
             select 1
               from public.barras_diarias b
              where b.simbolo = u.simbolo
                and b.fecha <= p_desde + 7
           )
     order by u.simbolo;
end;
$$;

comment on function private.simbolos_sin_historia(date) is
  'Símbolos del universo sin ninguna barra diaria hasta 7 días después de p_desde: los que faltan cargar (docs/10 §12).';

revoke all on function private.simbolos_sin_historia(date) from public, anon, authenticated;

-- Guarda un arreglo de barras diarias: [{simbolo, fecha, apertura, maximo, minimo, cierre,
-- volumen}, …]. Es idempotente: una barra que ya existe no se reemplaza ni se duplica, así que
-- repetir la carga inicial no cambia nada (CA-3). Devuelve cuántas filas nuevas quedaron.
-- Una barra que viola las restricciones de la tabla (barras_diarias_coherente) hace fallar el
-- lote completo: el adaptador de mercado ya descarta las incoherentes antes de llegar aquí.
create function private.guardar_barras_diarias(p_datos jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nuevas integer;
begin
  if p_datos is null or jsonb_typeof(p_datos) <> 'array' then
    raise exception 'guardar_barras_diarias: se esperaba un arreglo';
  end if;

  insert into public.barras_diarias (simbolo, fecha, apertura, maximo, minimo, cierre, volumen)
  select d.simbolo, d.fecha, d.apertura, d.maximo, d.minimo, d.cierre, d.volumen
    from jsonb_to_recordset(p_datos) as d(
           simbolo  text,
           fecha    date,
           apertura numeric,
           maximo   numeric,
           minimo   numeric,
           cierre   numeric,
           volumen  bigint
         )
  on conflict (simbolo, fecha) do nothing;

  get diagnostics v_nuevas = row_count;
  return v_nuevas;
end;
$$;

comment on function private.guardar_barras_diarias(jsonb) is
  'Guarda barras diarias sin duplicar ni reemplazar las existentes; devuelve las filas nuevas (docs/10 §12, CA-3).';

revoke all on function private.guardar_barras_diarias(jsonb) from public, anon, authenticated;
