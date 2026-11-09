-- HU-013 · Datos iniciales: el fondo único y sus cinco subcuentas fijas, en 0 y con los interruptores
-- apagados (CA-1). Las subcuentas de cupo las crea private.crear_cupo() (HU-017).
-- Idempotente: no repite el fondo ni las subcuentas si ya existen.

insert into public.fondos (nombre)
select 'Fondo RiTech' where not exists (select 1 from public.fondos);

insert into public.subcuentas (fondo_id, tipo, bolsillo)
select f.id, t.tipo, t.bolsillo
from public.fondos f
cross join (values
  ('reserva'::public.tipo_subcuenta,        'reserva'::public.bolsillo),
  ('arriesgadas'::public.tipo_subcuenta,    'arriesgadas'::public.bolsillo),
  ('usuarios_comun'::public.tipo_subcuenta, 'usuarios'::public.bolsillo),
  ('externa'::public.tipo_subcuenta,        null),
  ('resultados'::public.tipo_subcuenta,     null)
) as t (tipo, bolsillo)
where not exists (select 1 from public.subcuentas s where s.fondo_id = f.id and s.tipo = t.tipo);
