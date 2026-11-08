-- HU-033 · Catálogo completo de parámetros (docs/02 §10) y su historial (docs/06 §5.6).
-- La tabla `parametros` nació en HU-002 con las dos claves de `auth.*`; aquí se agrega el resto del
-- catálogo con su tipo, rango y descripción, y la tabla `parametros_historial`. La escritura la hace
-- solo public.actualizar_parametro (migración siguiente): ni la API ni service_role escriben directo.
--
-- Convenciones del catálogo:
--  * tipo 'numero': minimo/maximo son el rango de la tabla de 02 §10; nulo = sin tope ("≥ 0" es minimo 0).
--  * cupos.maximo_usd "sin límite" se guarda como JSON null (RN-19 lo leerá así).
--  * ia.modelo_* son texto: la lista de modelos permitidos la valida HU-054 (CB-79).
--  * ia.horizonte.* son texto: solo intradía, días o semanas (lo valida la función de cambio).

insert into public.parametros (clave, valor, tipo, minimo, maximo, descripcion) values
  ('reparto.pct_reserva',      '50'::jsonb,  'numero', 0, 100, 'Porcentaje del reparto que va a la Reserva. Los tres reparto.pct_* suman 100 (RN-02, RN-08, RN-26).'),
  ('reparto.pct_arriesgadas',  '25'::jsonb,  'numero', 0, 100, 'Porcentaje del reparto que va a Arriesgadas. Los tres reparto.pct_* suman 100 (RN-02, RN-08, RN-26).'),
  ('reparto.pct_usuarios',     '25'::jsonb,  'numero', 0, 100, 'Porcentaje del reparto que va a Usuarios. Los tres reparto.pct_* suman 100 (RN-02, RN-08, RN-26).'),
  ('aprobacion.umbral_doble_usd', '400'::jsonb, 'numero', 0, null, 'Monto en USD desde el cual una operación pide doble aprobación (RR-13).'),
  ('sugerencias.minutos_vencimiento', '30'::jsonb, 'numero', 5, 240, 'Minutos tras los cuales vence una sugerencia sin decidir.'),
  ('sugerencias.banda_precio_pct',    '1.0'::jsonb, 'numero', 0.2, 5, 'Banda de precio permitida desde la sugerencia, en % (RR-12, RN-23, RN-24).'),
  ('sugerencias.max_por_cupo_dia',    '3'::jsonb,   'numero', 1, 20, 'Máximo de sugerencias por cupo y por día (RR-16).'),
  ('sugerencias.aviso_previo_min',    '5'::jsonb,   'numero', 1, 30, 'Minutos antes del vencimiento en que se avisa "por vencer".'),
  ('riesgo.arriesgadas.max_pct_operacion', '20'::jsonb, 'numero', 1, 100, 'Arriesgadas: máximo % del bolsillo en una operación (RR-04).'),
  ('riesgo.arriesgadas.max_pct_simbolo',   '40'::jsonb, 'numero', 1, 100, 'Arriesgadas: máximo % del bolsillo en un símbolo (RR-05).'),
  ('riesgo.arriesgadas.stop_min_pct',      '3'::jsonb,  'numero', 0.5, 50, 'Arriesgadas: distancia mínima del stop, en % (RR-08).'),
  ('riesgo.arriesgadas.stop_max_pct',      '20'::jsonb, 'numero', 0.5, 50, 'Arriesgadas: distancia máxima del stop, en % (RR-08).'),
  ('riesgo.arriesgadas.perdida_diaria_max_pct', '5'::jsonb, 'numero', 1, 50, 'Arriesgadas: pérdida diaria máxima, en % (RR-19).'),
  ('riesgo.cupo.max_pct_operacion', '50'::jsonb,  'numero', 1, 100, 'Cupo: máximo % del cupo en una operación (RR-04).'),
  ('riesgo.cupo.max_pct_simbolo',   '100'::jsonb, 'numero', 1, 100, 'Cupo: máximo % del cupo en un símbolo (RR-05).'),
  ('riesgo.cupo.stop_min_pct',      '2'::jsonb,   'numero', 0.5, 50, 'Cupo: distancia mínima del stop, en % (RR-08).'),
  ('riesgo.cupo.stop_max_pct',      '15'::jsonb,  'numero', 0.5, 50, 'Cupo: distancia máxima del stop, en % (RR-08).'),
  ('riesgo.cupo.stop_defecto_pct',     '8'::jsonb,  'numero', 0.5, 100, 'Cupo: stop precargado en las órdenes manuales, en %.'),
  ('riesgo.cupo.objetivo_defecto_pct', '15'::jsonb, 'numero', 0.5, 100, 'Cupo: objetivo precargado en las órdenes manuales, en %.'),
  ('riesgo.orden_minima_usd',      '10'::jsonb, 'numero', 1, 1000, 'Monto mínimo de una orden, en USD (RR-06).'),
  ('riesgo.enfriamiento_horas',    '24'::jsonb, 'numero', 0, 168, 'Horas de enfriamiento tras una operación (RR-20).'),
  ('mercado.minutos_tras_apertura', '5'::jsonb,  'numero', 0, 60, 'Minutos tras la apertura en que no se compra (RR-07).'),
  ('mercado.minutos_antes_cierre',  '15'::jsonb, 'numero', 0, 60, 'Minutos antes del cierre en que no se compra (RR-07).'),
  ('mercado.max_antiguedad_cotizacion_seg', '60'::jsonb, 'numero', 15, 600, 'Antigüedad máxima de una cotización para operar, en segundos (RR-11).'),
  ('ejecucion.minutos_max_llenado', '5'::jsonb, 'numero', 1, 60, 'Minutos tras los cuales se cancela una entrada no llenada.'),
  ('ia.minutos_entre_ciclos',  '15'::jsonb,  'numero', 5, 120, 'Frecuencia del agente, en minutos.'),
  ('ia.umbral_evento_qqq_pct', '1.5'::jsonb, 'numero', 0.5, 10, 'Movimiento brusco de QQQ que dispara un ciclo extra, en %.'),
  ('ia.modelo_contexto', '"deepseek-flash"'::jsonb, 'texto', null, null, 'Modelo que genera el contexto (docs/07 §5). La lista permitida la valida HU-054.'),
  ('ia.modelo_jev',      '"jev-1.13.0"'::jsonb,     'texto', null, null, 'Modelo de JEV (docs/07 §5). La lista permitida la valida HU-054.'),
  ('ia.candidatos_max',  '10'::jsonb, 'numero', 1, 30, 'Candidatas de Arriesgadas que JEV evalúa en cada ciclo.'),
  ('ia.contexto_max_minutos', '90'::jsonb, 'numero', 15, 480, 'Vigencia del contexto de DeepSeek, en minutos.'),
  ('ia.noticias_horas',  '72'::jsonb, 'numero', 6, 168, 'Ventana de noticias para el contexto, en horas.'),
  ('ia.timeout_contexto_seg', '60'::jsonb, 'numero', 5, 120, 'Espera máxima a DeepSeek, en segundos.'),
  ('ia.timeout_jev_seg',      '10'::jsonb, 'numero', 5, 120, 'Espera máxima a JEV, en segundos.'),
  ('ia.pct_base.usuarios',    '30'::jsonb, 'numero', 1, 100, 'Porcentaje base del disponible de Usuarios antes del factor de confianza (docs/07 §7.1).'),
  ('ia.pct_base.arriesgadas', '15'::jsonb, 'numero', 1, 100, 'Porcentaje base del disponible de Arriesgadas antes del factor de confianza (docs/07 §7.1).'),
  ('ia.stop_atr_multiplo',        '2.0'::jsonb, 'numero', 0.5, 5, 'Múltiplo del ATR para calcular el stop.'),
  ('ia.relacion_objetivo_stop',   '2.0'::jsonb, 'numero', 0.5, 5, 'Relación objetivo/stop para calcular el objetivo.'),
  ('ia.horizonte.usuarios',    '"semanas"'::jsonb, 'texto', null, null, 'Horizonte de decisión y evaluación de Usuarios: intradía, días o semanas.'),
  ('ia.horizonte.arriesgadas', '"días"'::jsonb,    'texto', null, null, 'Horizonte de decisión y evaluación de Arriesgadas: intradía, días o semanas.'),
  ('jev.confianza_minima', '0.65'::jsonb, 'numero', 0.50, 0.95, 'Confianza mínima de JEV para comprar (RR-09).'),
  ('jev.confianza_venta',  '0.65'::jsonb, 'numero', 0.50, 0.95, 'Confianza mínima de JEV para vender.'),
  ('jev.puntaje_minimo',   '0.60'::jsonb, 'numero', 0, 1, 'Puntaje compuesto mínimo.'),
  ('jev.umbral_contradiccion', '0.5'::jsonb, 'numero', 0.1, 0.9, 'Umbral de contradicción entre datos y contexto.'),
  ('ia.presupuesto_mensual_usd', '20'::jsonb, 'numero', 0, null, 'Presupuesto mensual de DeepSeek + JEV, en USD. Al superarse el agente se pausa y avisa.'),
  ('rebalanceo.desviacion_pp', '5'::jsonb, 'numero', 1, 50, 'Desviación en puntos porcentuales que dispara el rebalanceo (RN-33).'),
  ('conciliacion.tolerancia_usd', '1.00'::jsonb, 'numero', 0, 100, 'Descuadre aceptable de la conciliación, en USD.'),
  ('conciliacion.minutos_entre',  '5'::jsonb,    'numero', 1, 60, 'Frecuencia de la conciliación, en minutos.'),
  ('cupos.maximo_usd', 'null'::jsonb, 'numero', 0, null, 'Cupo máximo por persona, en USD (RN-19). JSON null = sin límite.'),
  ('app.minutos_bloqueo', '5'::jsonb, 'numero', 1, 60, 'Minutos en segundo plano tras los cuales la app pide la biometría (docs/04 §8).');

-- Historial de cambios (docs/06 §5.6). Solo lo llena public.actualizar_parametro.
create table public.parametros_historial (
  id              bigserial primary key,
  clave           text not null references public.parametros (clave),
  valor_anterior  jsonb not null,
  valor_nuevo     jsonb not null,
  cambiado_por    uuid not null references public.perfiles (id),
  cambiado_en     timestamptz not null default now(),
  motivo          text not null check (btrim(motivo) <> '')
);

create index parametros_historial_clave_idx on public.parametros_historial (clave, cambiado_en desc);

comment on table public.parametros_historial is
  'Cada cambio de un parámetro: valor anterior, nuevo, quién, cuándo y motivo (docs/06 §5.6). Solo lo lee el Administrador (docs/03 §4.3); se escribe desde actualizar_parametro.';

alter table public.parametros_historial enable row level security;
revoke all on table public.parametros_historial from public, anon, authenticated, service_role;
revoke all on sequence public.parametros_historial_id_seq from public, anon, authenticated, service_role;
grant select on table public.parametros_historial to authenticated;

create policy parametros_historial_lectura on public.parametros_historial
for select to authenticated
using ((select private.rol_actual()) = 'administrador');

comment on policy parametros_historial_lectura on public.parametros_historial is
  'Solo el Administrador con la cuenta activa (docs/03 §4.3).';

-- parametros: HU-002 solo cerró la escritura a la API; aquí también a service_role.
revoke insert, update, delete, truncate on table public.parametros from service_role;
