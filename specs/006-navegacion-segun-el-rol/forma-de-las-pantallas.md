# Forma de las pantallas de HU-006 (`/impeccable shape`)

T006. Brief de diseño, sin código. Modo: **Operate** (navegación de una app de trabajo: precisión y consistencia, no expresión). El mundo visual ya está elegido: `DESIGN.md` (Almanaque). Hecho de forma autónoma, sin entrevista, porque la historia, `DESIGN.md` y el plan cierran las preguntas; lo supuesto está marcado como **Supuesto**.

## 1. Quién llega y qué necesita

Una persona con sesión, de uno de tres roles, casi siempre en el teléfono (el Administrador, sobre todo en la web de escritorio). Quiere **moverse sin pensar**: ver solo lo de su rol, saber en qué sección está y cambiar de una a otra en un toque. Quien tiene la cuenta suspendida solo necesita entender qué pasó y poder salir. Éxito: nadie ve una pestaña que no puede abrir; nadie queda atrapado.

## 2. Cascarón de navegación

**Teléfono (< 840 dp): la isla** (`BarraDePestanas`, ya diseñada en HU-116). Cápsula flotante abajo con la pestaña actual en píldora `morado-tenue` con ícono y rótulo, y las demás solo con el ícono. Cuatro destinos como máximo, que es el tope de la isla y el del MVP corto:

| Rol | Destinos, en este orden |
|---|---|
| Usuario | Mercado · Oportunidades · Mi cupo · Alertas |
| Analista | Mercado · Oportunidades · Alertas |
| Administrador | Mercado · Oportunidades · Alertas · Administración |

Íconos (Material, contorno): Mercado `show_chart`, Oportunidades `query_stats`, Mi cupo `account_balance_wallet_outlined`, Alertas `notifications_none` (los mismos del catálogo de HU-116), Administración `admin_panel_settings_outlined`. **Supuesto**: el ícono de Administración.

**Ventana ancha (≥ 840 dp): el riel** (`NavigationRail` con `navigationRailTheme` de `tema.dart`), a la izquierda, con los **mismos destinos en el mismo orden**, ícono y rótulo siempre visibles, y el contenido a su derecha. Sin la isla. **Supuesto**: 840 dp es el umbral (la clase "expandida" de Material 3); entre 600 y 840 dp se sigue viendo la isla.

Comportamiento común: el destino actual sale de la ruta y una subruta (`/admin/usuarios`) marca su sección; tocar el destino actual no recarga; cada destino mide al menos 48 dp, tiene foco de teclado y conserva su nombre completo para el lector de pantalla; sin movimiento propio salvo el de la isla (200 ms, ya definido). Cada pantalla pone su propia barra superior con el título de la sección; el cascarón no añade otra.

## 3. Marcador de sección (Oportunidades, Mi cupo, Alertas, Administración)

Mientras la historia de cada sección no construya su pantalla: `BarraSuperior` con el nombre de la sección (el mismo rótulo del menú) y un `EstadoVacio` centrado en una hoja. Nada de "próximamente" con tono de marketing, ni números de historia, ni íconos decorativos.

- Título del estado vacío: **"Aún no está disponible"**.
- Mensaje: **"Esta sección se habilita en una próxima entrega."**
- Sin botón: no hay nada que hacer aquí y el menú sigue a la vista.

**Supuesto**: esos dos textos (no están en `docs/`).

## 4. Pantalla de cuenta suspendida (`/cuenta-suspendida`)

Fuera del cascarón: sin menú, porque no hay a dónde ir. Misma estructura que la pantalla de ingreso: barra grafito con "RiTech Inversiones" y una hoja blanca sobre papel (máximo 420 dp, alineada arriba):

- Título (headline small): **"Cuenta suspendida"**.
- Mensaje (body, tinta): **"Tu cuenta está suspendida. Comunícate con el administrador."** (texto de `docs/04` §11, sin cambios).
- Un botón secundario de ancho completo: **"Cerrar sesión"**. Mientras cierra dice "Procesando…" (botón de sistema).
- Pie fuera de la hoja, igual que en el ingreso: "MVP en paper trading: una persona siempre aprueba." (mismo texto y estilo).

Sin aviso de error (no es un error de una acción) y sin rojo; sin morado. **Supuesto**: el título "Cuenta suspendida" y el botón "Cerrar sesión". Un cierre de sesión que falla vuelve a mostrar el botón sin mensaje técnico: la persona puede reintentar.

## 5. Layout, texto grande y modos

- Margen lateral de 16 dp; módulo de 4 dp; objetivos de 48 dp.
- **Texto al 200 %**: la isla ya limita la escala del rótulo (1,4) y recorta con puntos suspensivos; el riel muestra el rótulo completo con su ancho mínimo; la hoja de cuenta suspendida crece en alto con su contenido y se desplaza.
- Claro y oscuro con los mismos roles; no hay colores nuevos (los pares de `tema_test.dart` ya cubren tinta, tinta suave y tinta tenue sobre hoja y papel).
- Sin movimiento propio. El cambio de pestaña lo anima la isla (200 ms, y sin animación si el sistema pide quitarla).

## 6. Antiobjetivos

Una quinta pestaña para "Nueva orden" (la isla no la admite; la acción va en la tarjeta de detalle); menús distintos por plataforma; badges o contadores de colores sobre las pestañas (HU-085 decide cómo avisar alertas); el nombre o el rol de la persona en el cascarón (es de HU-008); un cuadro de error rojo en la cuenta suspendida; mostrar pestañas deshabilitadas o "bloqueadas" de otros roles (se ocultan, no se muestran).

## 7. Decisiones abiertas (no las inventa quien construye)

1. **Nueva orden manual** no es pestaña (plan D-2): lectura de `docs/03` §3 que se anota en el informe; si Javier prefiere otra, cambia el registro de destinos.
2. **Umbral de 840 dp** y el **ícono de Administración**.
3. Los textos marcados como **Supuesto**.

## 8. Verificación esperada (T015)

Revisar en Chrome a 360 dp y a 1280 dp, claro y oscuro, escala de texto 1,0 y 2,0, con los tres roles (menú, destino actual, marcador), un rol intentando abrir `#/admin` y la cuenta suspendida; contraste, foco de teclado y lectura con lector de pantalla; el emulador de Android solo si la RAM de la PC lo permite.
