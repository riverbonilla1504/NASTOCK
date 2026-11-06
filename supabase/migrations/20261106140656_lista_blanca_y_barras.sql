-- HU-026 · Lista blanca del universo y tablas de barras.
-- Fuentes: docs/06 §3 (tipo bolsillo) y §5.2 (mercado), docs/06 §7 (RLS, escrituras solo por funciones),
-- docs/03 §4.3 (lectura), docs/10 §12 (universo del NASDAQ-100).
--
-- Escritura: ninguna directa. Las barras las guardan las funciones de private (D-66) y la lista
-- blanca la editará actualizar_lista_blanca (HU-036).

-- Bolsillos del fondo (docs/06 §3). Esta es la primera tabla que lo usa: las historias
-- siguientes no deben volver a crearlo.
create type public.bolsillo as enum ('reserva', 'arriesgadas', 'usuarios');

-- Lista blanca ---------------------------------------------------------------------------------

create table public.lista_blanca (
  bolsillo         public.bolsillo not null check (bolsillo <> 'reserva'),
  simbolo          text not null,
  nombre           text not null,
  sector           text,                               -- para el contexto y las etiquetas de JEV; nulo en los ETF
  en_nasdaq100     boolean not null default false,
  activo           boolean not null default true,
  fraccionable     boolean,                            -- atributo del activo en Alpaca (HU-027)
  negociable       boolean,                            -- ídem; si pasa a false se desactiva y se alerta
  sincronizado_en  timestamptz,
  notas            text,
  actualizado_por  uuid,                               -- sin llave foránea a perfiles hasta que HU-001 esté en main
  actualizado_en   timestamptz not null default now(),
  primary key (bolsillo, simbolo)
);

comment on table public.lista_blanca is
  'Símbolos que se pueden ver y operar en cada bolsillo (docs/06 §5.2). QQQ se ingiere siempre, aunque no esté activo en ningún bolsillo: es la referencia del índice.';
comment on column public.lista_blanca.sector is
  'Sector GICS en inglés para las acciones; nulo en los ETF.';

-- Barras diarias: se guardan siempre ----------------------------------------------------------

create table public.barras_diarias (
  simbolo   text not null,
  fecha     date not null,                             -- día de mercado en Nueva York
  apertura  numeric(14,4) not null,
  maximo    numeric(14,4) not null,
  minimo    numeric(14,4) not null,
  cierre    numeric(14,4) not null,
  volumen   bigint not null,
  primary key (simbolo, fecha),
  constraint barras_diarias_coherente check (
    minimo > 0
    and volumen >= 0
    and maximo >= greatest(apertura, cierre, minimo)
    and minimo <= least(apertura, cierre, maximo)
  )
);

comment on table public.barras_diarias is
  'Resumen de cada día de mercado de cada símbolo del universo (docs/06 §5.2). Se guardan siempre.';

-- Barras de minuto: 5 días, solo ETF y símbolos con posiciones (la limpieza es de HU-029) -----

create table public.barras_minuto (
  simbolo   text not null,
  momento   timestamptz not null,
  apertura  numeric(14,4) not null,
  maximo    numeric(14,4) not null,
  minimo    numeric(14,4) not null,
  cierre    numeric(14,4) not null,
  volumen   bigint not null,
  primary key (simbolo, momento),
  constraint barras_minuto_coherente check (
    minimo > 0
    and volumen >= 0
    and maximo >= greatest(apertura, cierre, minimo)
    and minimo <= least(apertura, cierre, maximo)
  )
);

comment on table public.barras_minuto is
  'Barras de un minuto (docs/06 §5.2). La ingesta de precios (HU-028) las llena y la limpieza diaria (HU-029) borra las de más de 5 días.';

-- Seguridad ------------------------------------------------------------------------------------
-- RLS activo y sin políticas de escritura. Además se quitan los permisos de escritura: así un
-- INSERT, UPDATE o DELETE directo falla con "permiso denegado" y no se ignora en silencio.
-- anon no tiene acceso a nada (docs/06 §7, regla 2).

alter table public.lista_blanca enable row level security;
alter table public.barras_diarias enable row level security;
alter table public.barras_minuto enable row level security;

revoke all on table public.lista_blanca from public, anon, authenticated;
revoke all on table public.barras_diarias from public, anon, authenticated;
revoke all on table public.barras_minuto from public, anon, authenticated;

grant select on table public.lista_blanca to authenticated;
grant select on table public.barras_diarias to authenticated;
grant select on table public.barras_minuto to authenticated;

-- Lectura para toda persona autenticada (docs/03 §4.3: ✅ en los tres roles).
create policy lista_blanca_lectura on public.lista_blanca
  for select to authenticated using (true);
create policy barras_diarias_lectura on public.barras_diarias
  for select to authenticated using (true);
create policy barras_minuto_lectura on public.barras_minuto
  for select to authenticated using (true);

-- Semilla del universo (docs/06 §5.2, docs/10 §12, D-06, Q-13, Q-20) --------------------------
-- Usuarios: QLD y QQQ. Arriesgadas: TQQQ y los componentes del NASDAQ-100 con su sector.
-- Los componentes salen de la composición del índice a 2026-11-05; Alpaca no informa qué
-- acciones lo forman, así que la mantiene el Administrador (HU-036).

insert into public.lista_blanca (bolsillo, simbolo, nombre, sector, en_nasdaq100) values
  ('usuarios', 'QLD', 'ProShares Ultra QQQ', null, false),
  ('usuarios', 'QQQ', 'Invesco QQQ Trust, Series 1', null, false),
  ('arriesgadas', 'TQQQ', 'ProShares UltraPro QQQ', null, false),
  ('arriesgadas', 'AAPL', 'Apple Inc.', 'Information Technology', true),
  ('arriesgadas', 'ABNB', 'Airbnb, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'ADBE', 'Adobe Inc.', 'Information Technology', true),
  ('arriesgadas', 'ADI', 'Analog Devices, Inc.', 'Information Technology', true),
  ('arriesgadas', 'ADP', 'Automatic Data Processing, Inc.', 'Industrials', true),
  ('arriesgadas', 'ADSK', 'Autodesk, Inc.', 'Information Technology', true),
  ('arriesgadas', 'AEP', 'American Electric Power Company, Inc.', 'Utilities', true),
  ('arriesgadas', 'ALAB', 'Astera Labs, Inc.', 'Information Technology', true),
  ('arriesgadas', 'ALNY', 'Alnylam Pharmaceuticals, Inc.', 'Health Care', true),
  ('arriesgadas', 'AMAT', 'Applied Materials, Inc.', 'Information Technology', true),
  ('arriesgadas', 'AMD', 'Advanced Micro Devices, Inc.', 'Information Technology', true),
  ('arriesgadas', 'AMGN', 'Amgen Inc.', 'Health Care', true),
  ('arriesgadas', 'AMZN', 'Amazon.com, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'APP', 'AppLovin Corporation', 'Information Technology', true),
  ('arriesgadas', 'ARM', 'Arm Holdings plc', 'Information Technology', true),
  ('arriesgadas', 'ASML', 'ASML Holding N.V.', 'Information Technology', true),
  ('arriesgadas', 'AVGO', 'Broadcom Inc.', 'Information Technology', true),
  ('arriesgadas', 'AXON', 'Axon Enterprise, Inc.', 'Industrials', true),
  ('arriesgadas', 'BKNG', 'Booking Holdings Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'BKR', 'Baker Hughes Company', 'Energy', true),
  ('arriesgadas', 'CCEP', 'Coca-Cola Europacific Partners PLC', 'Consumer Staples', true),
  ('arriesgadas', 'CDNS', 'Cadence Design Systems, Inc.', 'Information Technology', true),
  ('arriesgadas', 'CEG', 'Constellation Energy Corporation', 'Utilities', true),
  ('arriesgadas', 'CMCSA', 'Comcast Corporation', 'Communication Services', true),
  ('arriesgadas', 'COST', 'Costco Wholesale Corporation', 'Consumer Staples', true),
  ('arriesgadas', 'CPRT', 'Copart, Inc.', 'Industrials', true),
  ('arriesgadas', 'CRWD', 'CrowdStrike Holdings, Inc.', 'Information Technology', true),
  ('arriesgadas', 'CRWV', 'CoreWeave, Inc.', 'Information Technology', true),
  ('arriesgadas', 'CSCO', 'Cisco Systems, Inc.', 'Information Technology', true),
  ('arriesgadas', 'CSX', 'CSX Corporation', 'Industrials', true),
  ('arriesgadas', 'CTAS', 'Cintas Corporation', 'Industrials', true),
  ('arriesgadas', 'DASH', 'DoorDash, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'DDOG', 'Datadog, Inc.', 'Information Technology', true),
  ('arriesgadas', 'DXCM', 'DexCom, Inc.', 'Health Care', true),
  ('arriesgadas', 'EXC', 'Exelon Corporation', 'Utilities', true),
  ('arriesgadas', 'FANG', 'Diamondback Energy, Inc.', 'Energy', true),
  ('arriesgadas', 'FAST', 'Fastenal Company', 'Industrials', true),
  ('arriesgadas', 'FER', 'Ferrovial N.V.', 'Industrials', true),
  ('arriesgadas', 'FTNT', 'Fortinet, Inc.', 'Information Technology', true),
  ('arriesgadas', 'GEHC', 'GE HealthCare Technologies Inc.', 'Health Care', true),
  ('arriesgadas', 'GILD', 'Gilead Sciences, Inc.', 'Health Care', true),
  ('arriesgadas', 'GOOG', 'Alphabet Inc. (Class C)', 'Communication Services', true),
  ('arriesgadas', 'GOOGL', 'Alphabet Inc. (Class A)', 'Communication Services', true),
  ('arriesgadas', 'HON', 'Honeywell International Inc.', 'Industrials', true),
  ('arriesgadas', 'HONA', 'Honeywell Aerospace Inc.', 'Industrials', true),
  ('arriesgadas', 'IDXX', 'IDEXX Laboratories, Inc.', 'Health Care', true),
  ('arriesgadas', 'INTC', 'Intel Corporation', 'Information Technology', true),
  ('arriesgadas', 'INTU', 'Intuit Inc.', 'Information Technology', true),
  ('arriesgadas', 'ISRG', 'Intuitive Surgical, Inc.', 'Health Care', true),
  ('arriesgadas', 'KDP', 'Keurig Dr Pepper Inc.', 'Consumer Staples', true),
  ('arriesgadas', 'KLAC', 'KLA Corporation', 'Information Technology', true),
  ('arriesgadas', 'LIN', 'Linde plc', 'Materials', true),
  ('arriesgadas', 'LITE', 'Lumentum Holdings Inc.', 'Information Technology', true),
  ('arriesgadas', 'LRCX', 'Lam Research Corporation', 'Information Technology', true),
  ('arriesgadas', 'MAR', 'Marriott International, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'MCHP', 'Microchip Technology Incorporated', 'Information Technology', true),
  ('arriesgadas', 'MDLZ', 'Mondelez International, Inc.', 'Consumer Staples', true),
  ('arriesgadas', 'MELI', 'MercadoLibre, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'META', 'Meta Platforms, Inc.', 'Communication Services', true),
  ('arriesgadas', 'MNST', 'Monster Beverage Corporation', 'Consumer Staples', true),
  ('arriesgadas', 'MPWR', 'Monolithic Power Systems, Inc.', 'Information Technology', true),
  ('arriesgadas', 'MRNA', 'Moderna, Inc.', 'Health Care', true),
  ('arriesgadas', 'MRVL', 'Marvell Technology, Inc.', 'Information Technology', true),
  ('arriesgadas', 'MSFT', 'Microsoft Corporation', 'Information Technology', true),
  ('arriesgadas', 'MSTR', 'Strategy Inc', 'Information Technology', true),
  ('arriesgadas', 'MU', 'Micron Technology, Inc.', 'Information Technology', true),
  ('arriesgadas', 'NBIS', 'Nebius Group N.V.', 'Information Technology', true),
  ('arriesgadas', 'NFLX', 'Netflix, Inc.', 'Communication Services', true),
  ('arriesgadas', 'NVDA', 'NVIDIA Corporation', 'Information Technology', true),
  ('arriesgadas', 'NXPI', 'NXP Semiconductors N.V.', 'Information Technology', true),
  ('arriesgadas', 'ODFL', 'Old Dominion Freight Line, Inc.', 'Industrials', true),
  ('arriesgadas', 'ORLY', 'O''Reilly Automotive, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'PANW', 'Palo Alto Networks, Inc.', 'Information Technology', true),
  ('arriesgadas', 'PAYX', 'Paychex, Inc.', 'Industrials', true),
  ('arriesgadas', 'PCAR', 'PACCAR Inc', 'Industrials', true),
  ('arriesgadas', 'PDD', 'PDD Holdings Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'PEP', 'PepsiCo, Inc.', 'Consumer Staples', true),
  ('arriesgadas', 'PLTR', 'Palantir Technologies Inc.', 'Information Technology', true),
  ('arriesgadas', 'PYPL', 'PayPal Holdings, Inc.', 'Financials', true),
  ('arriesgadas', 'QCOM', 'QUALCOMM Incorporated', 'Information Technology', true),
  ('arriesgadas', 'REGN', 'Regeneron Pharmaceuticals, Inc.', 'Health Care', true),
  ('arriesgadas', 'RKLB', 'Rocket Lab Corporation', 'Industrials', true),
  ('arriesgadas', 'ROP', 'Roper Technologies, Inc.', 'Information Technology', true),
  ('arriesgadas', 'ROST', 'Ross Stores, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'SBUX', 'Starbucks Corporation', 'Consumer Discretionary', true),
  ('arriesgadas', 'SHOP', 'Shopify Inc.', 'Information Technology', true),
  ('arriesgadas', 'SNDK', 'Sandisk Corporation', 'Information Technology', true),
  ('arriesgadas', 'SNPS', 'Synopsys, Inc.', 'Information Technology', true),
  ('arriesgadas', 'SPCX', 'Space Exploration Technologies Corp.', 'Industrials', true),
  ('arriesgadas', 'STX', 'Seagate Technology Holdings plc', 'Information Technology', true),
  ('arriesgadas', 'TER', 'Teradyne, Inc.', 'Information Technology', true),
  ('arriesgadas', 'TMUS', 'T-Mobile US, Inc.', 'Communication Services', true),
  ('arriesgadas', 'TRI', 'Thomson Reuters Corporation', 'Industrials', true),
  ('arriesgadas', 'TSLA', 'Tesla, Inc.', 'Consumer Discretionary', true),
  ('arriesgadas', 'TTWO', 'Take-Two Interactive Software, Inc.', 'Communication Services', true),
  ('arriesgadas', 'TXN', 'Texas Instruments Incorporated', 'Information Technology', true),
  ('arriesgadas', 'VRTX', 'Vertex Pharmaceuticals Incorporated', 'Health Care', true),
  ('arriesgadas', 'WDAY', 'Workday, Inc.', 'Information Technology', true),
  ('arriesgadas', 'WDC', 'Western Digital Corporation', 'Information Technology', true),
  ('arriesgadas', 'WMT', 'Walmart Inc.', 'Consumer Staples', true),
  ('arriesgadas', 'XEL', 'Xcel Energy Inc.', 'Utilities', true);
