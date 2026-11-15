# Validación de HU-011

## Requisitos

README: Flutter 3.47.9, Docker Desktop con motor iniciado, Supabase CLI 2.122.0, Deno 2.x y Git Bash en Windows. Solo proveedores simulados y base local de pruebas.

## Preparación

```bash
flutter pub get
supabase start
supabase db reset
```

`db reset` reinicia los datos locales de prueba. Para funciones, datos y app seguir los scripts del README. No ejecutar contra la nube.

## Casos esperados tras implementar

1. Analista a Usuario como Administrador: cupo en cero y menú nuevo sin volver a ingresar.
2. Usuario con efectivo, sin posiciones/órdenes: devolución a usuarios_comun y cupo cerrado; suma del libro conservada.
3. Con posición u orden viva: CUPO_CON_POSICIONES y ningún cambio parcial.
4. Acción propia/último administrador: errores CA-4.
5. Usuario/Analista intenta cambiar roles: NO_AUTORIZADO; comprobar también autorización por perfil con JWT anterior tras perder permisos.
6. Evento de otra cuenta: no renovar sesión actual. Cierre de sesión durante renovación: no reabrir canales anteriores.

## Comprobación final

```bash
supabase test db
flutter test
scripts/verificar.sh
```

Son comandos pendientes de ejecución tras implementar. No cerrar #28 hasta pruebas completas y CI en verde.
