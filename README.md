# RiTech SAS · Plataforma de inversión asistida por IA (MVP)

Fondo de inversión de RiTech SAS en **paper trading**, dividido en tres
bolsillos (Reserva 50 %, Arriesgadas 25 %, Usuarios 25 %), donde una IA
analiza el NASDAQ-100 y sugiere cuándo comprar o vender, y **una persona
siempre aprueba o rechaza**.

- **IA principal** (código): recopila y verifica los datos del mercado.
- **DeepSeek**: explica el contexto a partir de noticias reales.
- **JEV** (TypeSafe AI): decide la mejor opción con probabilidades calibradas.
- **Tres roles**: Usuario (opera su cupo), Analista (aprueba el riesgo),
  Administrador (gobierna el dinero y las reglas).

**Stack**: Flutter (Android + web) · Supabase (Postgres, Auth, Realtime,
Edge Functions, Cron, colas) · Alpaca paper · DeepSeek · JEV · Firebase ·
GitHub Actions. Todo en planes gratuitos, salvo las IAs.

## Documentación

La especificación completa está en [`docs/`](docs/README.md) y es la fuente
de verdad del proyecto (también publicada en la wiki). Si vas a trabajar con
un agente de IA, las reglas están en [`CLAUDE.md`](CLAUDE.md).

| Para… | Lee |
|---|---|
| Entender el producto | [01 Visión](docs/01-vision-y-alcance.md) · [02 Negocio](docs/02-logica-de-negocio.md) · [07 IA](docs/07-agente-ia.md) |
| Arrancar el proyecto y conectar servicios | [16 Arranque](docs/16-arranque-del-repositorio.md) |
| Implementar una historia | [`CLAUDE.md`](CLAUDE.md) · [17 Mapa de módulos](docs/17-mapa-de-modulos.md) |
| Pruebas y CI/CD | [15 Calidad](docs/15-calidad-pruebas-y-ci-cd.md) |

## Estado

- Especificación v3.3 lista.
- **Siguiente paso**: crear el backlog en GitHub Projects con GitHub CLI y
  conectar los servicios ([16 §3–§7](docs/16-arranque-del-repositorio.md)).
- Aún no hay código.

## Desarrollo local

Cuando exista el código (épica E-01):

```bash
cp .env.example .env          # todo simulado por defecto: no hace falta ninguna llave
supabase start
supabase db reset
scripts/verificar.sh          # lo mismo que corre CI, incluido el E2E
```
