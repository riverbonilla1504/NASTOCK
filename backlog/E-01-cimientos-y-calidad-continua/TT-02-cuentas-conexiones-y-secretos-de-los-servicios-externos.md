# TT-02 · Cuentas, conexiones y secretos de los servicios externos

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-alta` |

## Qué hay que hacer y por qué

Crear y conectar las cuentas gratuitas (Supabase, Google Cloud con Firebase y Alpaca paper) y las de pago por uso (DeepSeek y TypeSafe JEV), cargar sus secretos y variables y comprobar cada conexión. Sin esto no se puede desplegar ni probar contra proveedores reales.

## Documentación fuente

16 §3.2 a §3.8 · 16 §4 · 04 §3 · 05 §10.1 · D-45

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Criterio de terminado

- [ ] Existe el proyecto Supabase `ritech-mvp` con Google habilitado, el proveedor de correo deshabilitado, el JWT en 900 s y los secretos `url_funciones` y `secreto_interno` en Vault.
- [ ] Existen los clientes OAuth Web y Android (`com.ritech.inversiones` con las huellas SHA-1 de debug y release) y Firebase en plan Spark con Cloud Messaging, Hosting, App Distribution (grupo `ritech-equipo`) y Crashlytics.
- [ ] Las verificaciones `curl` de Alpaca News, DeepSeek y JEV de 16 §3 responden bien, o queda anotada la alternativa: Q-19 para noticias y Cloudflare Workers AI para JEV (CB-90).
- [ ] Todos los secretos y variables de 16 §4.1 están cargados en GitHub Actions y ninguno está en el repositorio.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] Supabase: organización, proyecto `ritech-mvp` en la región Este de EE. UU. (Q-10), llaves publicable y secreta, token de acceso, `supabase login` y `supabase link`.
- [ ] Google Cloud: proyecto, pantalla de consentimiento Interna (o Externa en modo prueba, Q-22) con los alcances `openid`, `email` y `profile`, y clientes OAuth Web y Android.
- [ ] Firebase en el mismo proyecto: apps Android y Web, Cloud Messaging con su cuenta de servicio, Hosting, App Distribution, Crashlytics, cuenta de servicio para CI y llave de firma de Android fuera del repositorio.
- [ ] Alpaca: cuenta paper reiniciada con el monto del fondo, par de llaves y verificación del acceso a noticias.
- [ ] DeepSeek: cuenta, saldo mínimo y llave. TypeSafe: solicitud de acceso anticipado el primer día y llave, o cuenta de Cloudflare con Workers AI como alternativa.
- [ ] Cargar variables con `gh variable set` y secretos con `gh secret set`.
- [ ] Herramientas locales de 16 §3.7 y Claude Code de 16 §3.8: skill de TypeSafe y `gh` autenticado.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-01 · Repositorio, GitHub Projects y wiki](TT-01-repositorio-github-projects-y-wiki.md) | Los secretos y variables se cargan en el repositorio. |
| Habilita | [TT-08 · Despliegue continuo al proyecto MVP con prueba de humo](TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) | TT-08: necesita los proyectos y los secretos de Supabase y Firebase. |
| Habilita | [HU-005 · Ingresar con Google en Android y web](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) | HU-005: necesita los clientes OAuth de Google y el proveedor configurado en Supabase. |
| Habilita | [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) | HU-087: necesita Firebase Cloud Messaging configurado. |
