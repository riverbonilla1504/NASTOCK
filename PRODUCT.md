# Product

<!-- impeccable:product-schema 1 -->

> Derivado de `docs/01` a `docs/04` (D-67). No agrega reglas: si algo de aquí
> choca con `docs/`, manda `docs/`. Las respuestas de Javier del 2026-11-06
> están marcadas como tales.

## Platform

android

Una sola interfaz Flutter con Material 3 para Android (APK) y web. La web
muestra la misma interfaz y se adapta a ventanas anchas. iOS queda fuera del
MVP (`docs/01` §4).

## Users

Empresa cerrada: pocos participantes, conocidos, solo por invitación y con
cuenta de Google (Gmail personal: RiTech no tiene Google Workspace, 2026-11-08).
Un rol por persona (`docs/03` §1).

- **Usuario** (empleados de RiTech). Hace crecer su cupo dentro del bolsillo
  de Usuarios. En el MVP corto ve el mercado en vivo, Oportunidades de su
  bolsillo, su cupo (posiciones y resultado) y sus alertas, y crea órdenes
  manuales de compra y venta. Usa la app sobre todo en el teléfono
  (respuesta de Javier).
- **Analista** (personal de inversiones). Controla el riesgo del fondo. En
  el MVP corto solo supervisa: mercado, todas las Oportunidades y alertas
  (D-64). Sobre todo en el teléfono (respuesta de Javier).
- **Administrador** (gerencia y tesorería). Gobierna el dinero, las cuentas y
  los parámetros; nunca aprueba operaciones de mercado. En el MVP corto:
  usuarios e invitaciones, aportes de capital, cupos, parámetros e
  interruptores. Sobre todo en la web de escritorio (respuesta de Javier).

## Product Purpose

RiTech SAS tiene un fondo de inversión cerrado (capital de referencia
USD 10.000) cuyo desempeño depende del doble del NASDAQ-100. Un instrumento
×2 amplifica igual las ganancias y las pérdidas, así que el momento de entrar
y de salir importa más que en una inversión normal. RiTech no quiere que la
tecnología decida sola con su dinero, ni que sus empleados vigilen el
mercado todo el día (`docs/01` §1).

La plataforma es un sistema de IA que vigila el mercado y propone, y personas
que deciden. Es un **MVP en paper trading** (broker real, dinero ficticio)
para probar si el enfoque funciona (`docs/01` §2).

El MVP corto entrega cinco capacidades: iniciar sesión con Google, manejar
usuarios, ver las acciones del NASDAQ-100 en vivo, comprar y vender en paper
con órdenes manuales, y la IA que analiza y recomienda en Oportunidades con
su explicación (`docs/01` §4, D-58, D-65).

Cómo se sabe que funciona (`docs/01` §6, entre otros): al menos el 80 % de
las personas entiende la justificación de lo que propone la IA; el precio en
pantalla tiene menos de 30 s de retraso en horario de mercado; ninguna
operación viola una regla de riesgo y ninguna sale con datos desactualizados.

## Positioning

- **La IA propone, una persona decide.** Ninguna compra o venta discrecional
  sale sin una persona; las únicas órdenes automáticas son las protecciones
  que la persona ya aprobó con la compra (P1).
- **La IA no tiene llaves.** Ningún modelo habla con el broker (P2).
- **Ante la duda, no operar.** Datos viejos, integraciones caídas o
  respuestas inválidas detienen el sistema en vez de improvisar (P7).
- Una sola contabilidad de doble partida, separación de funciones entre roles
  y todo auditado (P4 a P6).

## Operating Context

- **Horario del mercado**: 9:30 a 16:00 de Nueva York. La app siempre muestra
  la hora de Bogotá y una cuenta regresiva a la apertura o al cierre. Fuera
  de horario no se crean compras.
- **Precios casi en vivo**: cada ~15 s en horario de mercado. Un precio
  viejo lleva la marca "dato desactualizado" y deshabilita la compra.
- **Conexión**: "Reconectando…" atenúa los datos; "Sin conexión" deshabilita
  los botones de decisión.
- **Decisiones y dinero**: se confirman con un diálogo que repite monto y
  símbolo (D-61). Mientras se envía, el botón muestra "Procesando…"; nada que
  toque dinero se actualiza antes de que responda el servidor.
- **Demostración fuera de horario** con el mercado simulado.
- **Idioma y formatos**: todo en español. Dinero en USD con dos decimales
  (`USD 10.000,00`). Horas en hora de Bogotá.

## Capabilities and Constraints

- Solo paper trading: ninguna orden mueve dinero real. Solo herramientas
  gratuitas, salvo las IAs.
- Ingreso solo con cuenta de Google (Gmail) invitada y solo por invitación. Sin
  correo y contraseña (salvo usuarios de prueba en local y CI).
- Los permisos se aplican en el servidor. La app oculta lo que un rol no
  puede usar para que la experiencia sea limpia; el menú de cada rol muestra
  solo las pantallas del MVP corto (`docs/03` §3).
- MVP corto sin bandeja de notificaciones ni push: cada pantalla muestra su
  propio estado en vivo (D-62).
- Los textos de error son los de `docs/04` §11 y `docs/06` §9. La app nunca
  muestra el texto crudo de una excepción.
- Términos del negocio (glosario de `docs/README.md`): fondo, bolsillo
  (Reserva, Arriesgadas, Usuarios), cupo, efectivo, retenido, disponible,
  posición, patrimonio, Oportunidades, orden, protección (stop-loss y
  take-profit), interruptores, paper trading.

## Brand Commitments

- Nombre visible: **RiTech Inversiones**, de RiTech SAS. No hay logo ni
  colores de marca previos: la identidad visual se construye en HU-116
  (respuesta de Javier).
- Diseño visual nuevo (D-67): la interfaz de la v2 no se copia. Solo es
  referencia de contenido y antirreferencia visual; no se conservan su
  paleta, sus widgets ni la fuente Poppins (decisión de Javier).
  Javier pidió explícitamente evitar la alerta genérica de etiqueta roja con
  ícono rojo y el estilo típico de "panel de IA".
- Voz: español, tuteo, frases cortas y directas que dicen qué pasó y qué
  hacer: "Tu correo no tiene una invitación vigente. Pídele una al
  administrador." (`docs/04` §11).

## Evidence on Hand

- La especificación completa en `docs/` y el backlog en `backlog/`.
- La app v2 (`github.com/T0m4s1n/ritech-sas-inversiones`), solo como
  referencia de contenido (qué pantallas, datos y flujos había) y como
  antirreferencia visual.
- No hay usuarios reales, resultados del fondo, rendimientos ni testimonios.
  Ninguna pantalla, ejemplo ni demostración debe inventarlos como reales.

## Product Principles

1. **La persona decide y lo sabe.** Cada pantalla deja claro qué propone la
   IA, por qué, y que la decisión es de la persona.
2. **Ante la duda, mostrarlo.** Un dato viejo, una conexión caída o un
   mercado cerrado se ven en la pantalla antes de que alguien actúe.
3. **Cifras exactas y verificables.** El dinero se muestra en USD con dos
   decimales y nunca se adelanta a la respuesta del servidor.
4. **Cada rol ve lo suyo.** La interfaz muestra solo lo que ese rol puede
   hacer.
5. **Es paper trading.** Nada sugiere que se mueve dinero real.

## Accessibility & Inclusion

WCAG 2.2 AA como mínimo (respuesta de Javier): contraste de 4,5:1 en el
texto, objetivos táctiles de al menos 48 dp, texto que escala con la
configuración del sistema y ningún estado ni variación que dependa solo del
color.
