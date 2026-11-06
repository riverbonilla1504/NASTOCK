# Cómo comprobar HU-107

Antes de cualquier comando `supabase`, tomar el candado del stack compartido (`mkdir C:/Users/Javier/.nastock-supabase-candado`) y soltarlo al terminar (`rmdir`).

## 1. Pruebas de base de datos (CA-1 a CA-5)

```bash
supabase db reset
supabase test db
```

Esperado: pasan `05_auditoria_tabla_y_lectura_test.sql`, `06_auditoria_auditar_test.sql` y `07_auditoria_inmutable_test.sql`, además de las de TT-03, TT-05, HU-001 y HU-026.

## 2. Revisión a mano (opcional)

Con el stack local arriba y la base recién reiniciada:

```bash
docker exec supabase_db_NASTOCK psql -U postgres -c "select private.auditar(null, 'ajuste.registrado', 'movimientos', '1', '{\"nota\":\"prueba\"}'::jsonb)"
docker exec supabase_db_NASTOCK psql -U postgres -c "update public.auditoria set accion = 'x'"
```

Esperado: la primera devuelve el `id` del registro; la segunda falla con `auditoria: la bitácora es inmutable (UPDATE no permitido)`. Después de probar, `supabase db reset` deja la bitácora vacía otra vez.

## 3. Todo

```bash
scripts/verificar.sh
```

Esperado: verde.
