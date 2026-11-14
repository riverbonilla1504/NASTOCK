# 18 · Estado del proyecto y traspaso

Corte al **2026-11-14**. Es el punto de partida para quien continúe el
proyecto: qué funciona, qué falta, cómo arrancar y a quién pedir cada acceso.
El alcance de la entrega lo fija **D-73**
([13 §1](13-decisiones-pendientes-riesgos.md#1-registro-de-decisiones)). Las
reglas de trabajo siguen en [`CLAUDE.md`](../CLAUDE.md) y en
[16](16-arranque-del-repositorio.md).

> **Ninguna llave va en este documento ni en el repositorio.** Aquí solo se
> dice qué cuenta existe y quién la tiene. Las llaves se piden por un canal
> privado.

---

## 1. El estado en una página

El **MVP corto** (D-58, [14 §4.1](14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58))
funciona de punta a punta en la nube y en local:

1. **Entrar**: con Google por invitación (Android y web); el primer
   administrador sale de la configuración del despliegue.
2. **Usuarios**: el Administrador invita y revoca invitaciones; cada rol ve
   su menú.
3. **Mercado en vivo**: el NASDAQ-100, QQQ, QLD y TQQQ con precios cada
   15 s, gráfica 1D · 1M · 1Y · All y estado del mercado.
4. **Fondo y cupos**: libro contable de doble partida, aportes con
   conciliación y reparto 50/25/25, cupos de cada empleado, parámetros e
   interruptores.
5. **IA**: el ciclo del agente evalúa candidatas con JEV y las muestra en
   **Oportunidades** con nivel (favorable, vigilar, desfavorable),
   probabilidades y explicación (D-70, D-72).
6. **Operar en paper**: orden manual de compra o venta en el cupo, envío a
   Alpaca paper con el motor de políticas, sincronización de llenados,
   posiciones con su protección y reparto de la ganancia realizada.

Todo con **dinero ficticio** (Alpaca paper). `main` tiene la CI en verde y el
despliegue continuo publica la base, las funciones, la web y el APK.

---

## 2. Lo construido

| Capacidad | Ítems en `main` |
|---|---|
| Base técnica | TT-01, TT-03 a TT-09 |
| Entrar y usuarios | HU-001 a HU-007, HU-083, HU-084, HU-097, HU-107 |
| Mercado | HU-026 a HU-030 |
| Fondo y cupos | HU-013, HU-014, HU-015, HU-017, HU-018, HU-019, HU-023, HU-033, HU-034, HU-099, HU-100, HU-101 |
| IA | HU-035, HU-037, HU-044 a HU-048 (con D-70 y D-72) |
| Operar en paper | HU-072 a HU-075, HU-091 |
| Diseño | HU-116 (D-67, D-69) |

Cada historia tiene su carpeta en `specs/` con `spec.md`, `plan.md` y
`tasks.md`, salvo las que se hicieron antes de adoptar spec-kit o como corte
de demo.

---

## 3. Lo que falta del MVP

Siguen dentro de la entrega (D-73): quedan para los demás integrantes del
equipo. Cada una tiene su issue y su archivo en `backlog/`.

### 3.1 Sin empezar

| Historia | Issue | Qué le falta a la app | Depende de |
|---|---|---|---|
| HU-077 · Protección nativa en compras de acciones enteras | #100 | Stop-loss y objetivo en Alpaca: sin esto no hay venta automática | HU-073, HU-074 (hechas) |
| HU-076 · Ver mis órdenes y cancelar | #99 | El Usuario no ve ni cancela sus órdenes | HU-075 (hecha) |
| HU-032 · Aviso de dato desactualizado | #51 | Con un precio viejo no se avisa ni se bloquea la compra | HU-030 (hecha) |
| HU-085 · Alertas del sistema por audiencia | #109 | No hay alertas: la pestaña Alertas es un marcador | HU-083, HU-084 (hechas) |
| HU-010 · Suspender y reactivar una cuenta | #27 | El Administrador no puede suspender desde la app | HU-001 (hecha) |
| HU-011 · Cambiar el rol de una cuenta | #28 | No se cambia el rol desde la app | HU-001 (hecha) |

### 3.2 A medias

| Historia | Qué funciona | Qué falta |
|---|---|---|
| HU-098 · Usuarios e invitaciones | La pantalla de invitaciones | La lista de usuarios con suspender y cambiar rol (HU-010, HU-011) |
| HU-015 · Confirmar el aporte | Conciliación y reparto | La alerta al Administrador si un aporte no se confirma (HU-085) |
| HU-035 · Salud de las integraciones | El registro de la salud | La alerta cuando una integración cae (HU-085) |
| HU-091 · Mis posiciones | La pantalla con la protección | La prueba pgTAP de `protecciones` (HU-077) |
| HU-097 · Sección de administración | La sección y la guía de primeros pasos | Ajustar el E2E-01 |

### 3.3 Escenarios E2E que faltan

[15 §4](15-calidad-pruebas-y-ci-cd.md#4-escenarios-e2e-obligatorios) pide E2E-01 a E2E-08
y E2E-11. Existen E2E-01, E2E-02, E2E-03, E2E-06 (parte de backend) y E2E-07.
Faltan **E2E-04** (aportes → cupos → Mi cupo), **E2E-05**, **E2E-08** (orden
manual → llenado → posición → venta; lo cierra HU-077) y **E2E-11**.

### 3.4 Orden sugerido

1. **HU-077** y con ella **E2E-08**: completa "comprar y vender".
2. **HU-076** y **HU-032**: cierran la pantalla de órdenes.
3. **HU-085**: destraba las alertas de HU-015 y HU-035.
4. **HU-010**, **HU-011** y **HU-098**: administración de cuentas.
5. **E2E-04**, **E2E-05** y **E2E-11**.

Las historias 1 a 4 se pueden repartir en paralelo: no tocan los mismos
módulos ([17](17-mapa-de-modulos.md)).

---

## 4. Cómo arrancar

1. Leer [`CLAUDE.md`](../CLAUDE.md) completo y, para la historia que se va a
   tomar, solo las secciones de sus módulos en [17](17-mapa-de-modulos.md).
2. Instalar las herramientas de [16 §3.7](16-arranque-del-repositorio.md#37-herramientas-locales).
   **Flutter 3.47.9**, la versión fijada en los flujos (EC-038).
3. **En local, todo simulado y sin llaves**:

   ```bash
   cp .env.example .env
   supabase start
   supabase db reset
   scripts/verificar.sh
   ```

4. **Contra la nube** (la demo): la app recibe `SUPABASE_URL`,
   `SUPABASE_PUBLISHABLE_KEY` y `GOOGLE_WEB_CLIENT_ID` con
   `--dart-define-from-file=<archivo>.json`. Ese archivo no se versiona; sus
   valores se piden al dueño de Supabase y de Google Cloud (§5).
5. Seguir el flujo de "Flujo para implementar una historia" de `CLAUDE.md`:
   issue → spec-kit → por capas → E2E → `verificar.sh` → PR.

---

## 5. Accesos

| Servicio | Para qué | Cuenta | Quién la tiene hoy | Qué pedir |
|---|---|---|---|---|
| GitHub · `riverbonilla1504/NASTOCK` | Código, CI, issues, proyecto "RiTech SAS · MVP" | Repositorio de River | River (dueño), Javier (Write) | Rol Write; los secretos de Actions los carga quien sea administrador |
| Supabase · proyecto **NasTock** (us-east-1) | Base, Auth, Realtime, Edge Functions, Vault | Organización de Supabase | Javier | Invitación a la organización |
| Google Cloud · **NasTock** | Ingreso con Google (OAuth) | Proyecto de Google Cloud | Javier | **Agregar el Gmail a "Test users"**: la pantalla de consentimiento está en *Testing* y solo entran esos correos |
| Firebase · `nastock-514020` | Hosting web, App Distribution, Crashlytics | Mismo proyecto de Google | Javier | Acceso al proyecto; entrar al grupo `ritech-equipo` de App Distribution |
| Alpaca · cuenta paper **NasTock** | Órdenes y datos de mercado | Cuenta de Alpaca | Javier | Las llaves de paper, por canal privado (o una cuenta paper propia para pruebas) |
| TypeSafe AI (JEV) | Decisiones de la IA | Cuenta de TypeSafe | Javier | La llave, por canal privado; en la nube ya está como secreto de Edge Functions |
| Llave de firma de Android (`.jks`) | Firmar el APK de release | Archivo fuera del repositorio | Javier (con respaldo) | Solo si se va a firmar a mano; el despliegue ya la usa desde los secretos |

En local no hace falta ninguna: todos los proveedores son simulados
([15 §3](15-calidad-pruebas-y-ci-cd.md#3-modo-simulado-y-datos-de-prueba)).

---

## 6. Pendientes operativos

- El token de Supabase dura lo que trae por defecto; [04 §8](04-autenticacion-oauth.md#8-sesión-en-la-app)
  pide 900 s. Falta ponerlo en el panel de Supabase o, si se prefiere el
  valor por defecto, cambiar la regla con la regla de oro 2.
- Borrar el proyecto viejo de Supabase "RiTech SAS" (us-west-2).
- River borra el token temporal con el que se cargaron los secretos de
  GitHub.
- Después de desplegar D-72, el interruptor `ia_activa` debe estar encendido
  (Administración → Parámetros e interruptores) para que Oportunidades se
  actualice; nace apagado y exige un aporte confirmado (RN-11).
- Migrar los imports de `material.dart` a `material_ui` cuando se suba
  Flutter (EC-038).

---

## 7. Limitaciones conocidas

- **Paper trading**: nada toca dinero real (D-44).
- **Sin noticias ni DeepSeek** (D-59): la IA decide con las métricas del
  mercado y JEV; las dimensiones de contexto valen 0,5.
- **Sin sugerencias de la IA** (D-65): la IA recomienda en Oportunidades y la
  persona opera con órdenes manuales. Solo opera el bolsillo de Usuarios
  (D-64): el Analista supervisa y no aprueba nada.
- **Precios de una sola bolsa (IEX)** en el plan gratuito de Alpaca.
- **Con la bolsa cerrada**, la IA evalúa con la última sesión pensando en la
  próxima apertura (D-70, D-72).
- Lo que falta del MVP está en §3; lo que queda fuera de la entrega, en D-73.
