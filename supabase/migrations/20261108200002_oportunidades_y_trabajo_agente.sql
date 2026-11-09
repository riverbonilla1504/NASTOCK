-- HU-048 · RPC `oportunidades(bolsillo)` y trabajo `ciclo_agente` de pg_cron (corte de demo D-70).
-- Fuentes: docs/03 §4.3 (el Usuario ve lo suyo solo por oportunidades()), docs/05 §7 (trabajos),
-- docs/07 §3 y §14.

-- Evaluaciones del último ciclo completado. El Analista y el Administrador ven todos los bolsillos;
-- el Usuario solo el de Usuarios (CA-2): si pide `arriesgadas` no recibe filas. `reserva` no tiene candidatas.
create function public.oportunidades(p_bolsillo public.bolsillo default null)
returns table (
  ciclo_id uuid,
  ciclo_terminado_en timestamptz,
  bolsillo public.bolsillo,
  simbolo text,
  tipo text,
  resultado text,
  calidad_datos text,
  puntaje_cuantitativo numeric,
  puntaje_compuesto numeric,
  confianza numeric,
  estado_contexto text,
  modelo_jev text,
  aportes jsonb,
  metricas jsonb,
  explicacion jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select e.ciclo_id, c.terminado_en, e.bolsillo, e.simbolo, e.tipo, e.resultado, e.calidad_datos,
         e.puntaje_cuantitativo, e.puntaje_compuesto, e.confianza, e.estado_contexto, e.modelo_jev,
         e.aportes, e.metricas, e.explicacion
    from public.evaluaciones_candidatos e
    join (
      select k.id, k.terminado_en
        from public.ciclos_agente k
       where k.estado = 'completado'
       order by k.iniciado_en desc
       limit 1
    ) c on c.id = e.ciclo_id
   where not e.es_sombra
     and case (select private.rol_actual())
           when 'analista' then true
           when 'administrador' then true
           when 'usuario' then e.bolsillo = 'usuarios'
           else false
         end
     and (p_bolsillo is null or e.bolsillo = p_bolsillo)
   order by
     case when e.resultado = 'elegida' then 0 when e.resultado like 'excluida:%' then 2 else 1 end,
     e.puntaje_compuesto desc nulls last,
     e.simbolo
$$;

comment on function public.oportunidades(public.bolsillo) is
  'Candidatas del último ciclo completado con puntaje, confianza, aportes y explicación. El Usuario solo recibe el bolsillo de Usuarios (docs/03 §4.3).';

revoke all on function public.oportunidades(public.bolsillo) from public, anon;
grant execute on function public.oportunidades(public.bolsillo) to authenticated;

-- Trabajo `ciclo_agente`: cada 5 minutos pregunta a SQL si le toca y solo entonces despierta a `agente`.
-- cron.schedule con un nombre existente reemplaza el trabajo.
select cron.schedule(
  'ciclo_agente',
  '*/5 * * * *',
  $$select private.despertar_funcion('agente') where private.ciclo_agente_pendiente()$$
);
