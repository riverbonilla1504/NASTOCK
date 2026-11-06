# Cómo comprobar HU-001

Antes de cualquier comando `supabase`, tomar el candado del stack compartido (`mkdir C:/Users/Javier/.nastock-supabase-candado`) y soltarlo al terminar (`rmdir`).

## 1. Pruebas de base de datos (CA-1 a CA-4 y CA-6)

```bash
supabase db reset
supabase test db
```

Esperado: pasan `02_perfiles_rls_test.sql` y `03_perfiles_roles_y_token_test.sql`, además de las de TT-03 y TT-05.

## 2. Inicio de sesión real (registro del hook, CA-1 y CA-5)

Con el stack reiniciado desde esta rama (`supabase stop` y `supabase start`, porque `config.toml` solo se lee al arrancar):

1. Crear una cuenta de prueba en Auth local con correo y contraseña de prueba.
2. Insertar su fila en `perfiles` con rol `analista` y estado `activo`.
3. Iniciar sesión y decodificar el `access_token`.

Esperado: el JWT trae `app_rol = "analista"` y `app_estado = "activo"`, y `exp - iat = 900`.

## 3. Todo

```bash
scripts/verificar.sh
```

Esperado: verde.
