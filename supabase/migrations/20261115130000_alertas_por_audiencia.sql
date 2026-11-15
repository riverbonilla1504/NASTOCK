-- HU-085 · docs/06 §5.5, docs/03 §4.3, docs/09 §3–4. CA-1 a CA-5.
create type public.severidad as enum ('info', 'advertencia', 'critica');
create type public.audiencia as enum ('todos', 'analistas', 'administradores', 'usuario');
create table public.alertas (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (btrim(tipo) <> ''),
  origen text not null default 'sistema' check (origen in ('ia', 'sistema')),
  severidad public.severidad not null,
  audiencia public.audiencia not null,
  usuario_id uuid references public.perfiles(id),
  titulo text not null check (btrim(titulo) <> ''),
  cuerpo text not null,
  referencia jsonb,
  clave_dedup text not null check (btrim(clave_dedup) <> ''),
  activa boolean not null default true,
  creado_en timestamptz not null default now(),
  resuelta_en timestamptz,
  version int not null default 1,
  constraint alertas_destinatario check ((audiencia = 'usuario') = (usuario_id is not null)),
  constraint alertas_resolucion check (activa = (resuelta_en is null))
);
create unique index alertas_activas_clave_unica on public.alertas(clave_dedup) where activa;
create index alertas_fecha on public.alertas(creado_en desc);
alter table public.alertas enable row level security;
revoke all on public.alertas from public, anon, authenticated, service_role;
grant select on public.alertas to authenticated;
create policy alertas_por_audiencia on public.alertas for select to authenticated using (
  private.rol_actual() is not null and (
    audiencia = 'todos'
    or (audiencia = 'usuario' and usuario_id = (select auth.uid()))
    or (audiencia = 'analistas' and private.es_supervisor())
    or (audiencia = 'administradores' and private.rol_actual() = 'administrador')
  )
);

create function private.publicar_alerta() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- ON CONFLICT reutiliza el id; el aviso no se vuelve a publicar.
  if tg_op = 'UPDATE' and new.activa = old.activa then return null; end if;
  perform private.publicar_evento('supervision', 'alerta',
    private.carga_evento('alertas', new.id::text, new.version,
      case when new.activa then 'activa' else 'resuelta' end));
  return null;
end;
$$;
revoke all on function private.publicar_alerta() from public, anon, authenticated, service_role;
create trigger alertas_publicar_evento after insert or update on public.alertas
  for each row execute function private.publicar_alerta();

create function private.crear_alerta(
  p_tipo text, p_audiencia public.audiencia, p_titulo text, p_cuerpo text, p_clave text,
  p_usuario_id uuid default null, p_severidad public.severidad default 'advertencia',
  p_referencia jsonb default null, p_origen text default 'sistema'
) returns uuid language sql security definer set search_path = '' as $$
  insert into public.alertas(tipo,audiencia,titulo,cuerpo,clave_dedup,usuario_id,severidad,referencia,origen)
  values (p_tipo,p_audiencia,p_titulo,p_cuerpo,p_clave,p_usuario_id,p_severidad,p_referencia,p_origen)
  on conflict (clave_dedup) where activa do update set clave_dedup = excluded.clave_dedup
  returning id;
$$;
revoke all on function private.crear_alerta(text,public.audiencia,text,text,text,uuid,public.severidad,jsonb,text)
  from public, anon, authenticated, service_role;

create function private.resolver_alerta(p_clave text) returns void
language sql security definer set search_path = '' as $$
  update public.alertas set activa = false, resuelta_en = now(), version = version + 1
   where clave_dedup = p_clave and activa;
$$;
revoke all on function private.resolver_alerta(text) from public, anon, authenticated, service_role;

-- calendario-mercado ya llama sincronizar_activos. El trigger conecta su cambio
-- sin alterar el contrato del adaptador y mantiene desactivación/aviso atómicos.
create function private.alertar_activo_no_negociable() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_clave text := 'activo_no_negociable:' || new.simbolo;
begin
  if old.activo and not new.activo and new.negociable = false then
    perform private.crear_alerta('activo_no_negociable', 'administradores',
      'Acción no negociable', new.simbolo || ' dejó de ser negociable y se desactivó de la lista blanca.',
      v_clave, p_referencia => jsonb_build_object('simbolo', new.simbolo));
  elsif new.negociable = true then
    perform private.resolver_alerta(v_clave);
  end if;
  return null;
end;
$$;
revoke all on function private.alertar_activo_no_negociable() from public, anon, authenticated, service_role;
create trigger lista_blanca_alertar_no_negociable after update of negociable, activo on public.lista_blanca
  for each row execute function private.alertar_activo_no_negociable();
comment on table public.alertas is 'HU-085: avisos por audiencia, clave única mientras activa y rearme al resolver. Personales solo para el destinatario.';
