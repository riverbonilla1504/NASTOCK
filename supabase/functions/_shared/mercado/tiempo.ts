// Fechas de mercado: el día de mercado es el de Nueva York (docs/06 §1: las horas se guardan
// en UTC y se muestran en hora de Bogotá, pero una barra diaria pertenece al día de la bolsa).
// Una fecha es un texto AAAA-MM-DD; sumar y restar días o años no depende de la zona horaria.

const MS_POR_DIA = 86_400_000;

const FORMATO_NY = new Intl.DateTimeFormat("en-CA", {
  timeZone: "America/New_York",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

/** Fecha (AAAA-MM-DD) y minutos desde la medianoche en Nueva York para un instante. */
export function horaDeNuevaYork(
  instante: Date,
): { fecha: string; minutos: number } {
  const partes = Object.fromEntries(
    FORMATO_NY.formatToParts(instante).map((p) => [p.type, p.value]),
  );
  return {
    fecha: `${partes.year}-${partes.month}-${partes.day}`,
    minutos: Number(partes.hour) * 60 + Number(partes.minute),
  };
}

/** Día de Nueva York en el que cae un instante. */
export function fechaDeNuevaYork(instante: Date): string {
  return horaDeNuevaYork(instante).fecha;
}

/**
 * Instante UTC de una fecha y unos minutos (desde la medianoche) de Nueva York. El horario de
 * verano se resuelve probando los dos desfases posibles (UTC−4 y UTC−5): el que vuelve a dar la
 * misma hora local es el correcto (CB-51).
 */
export function instanteDeNuevaYork(fecha: string, minutos: number): Date {
  const [anio, mes, dia] = fecha.split("-").map(Number);
  for (const desfase of [4, 5]) {
    const candidato = new Date(
      Date.UTC(anio, mes - 1, dia, 0, minutos + desfase * 60),
    );
    const local = horaDeNuevaYork(candidato);
    if (local.fecha === fecha && local.minutos === minutos) return candidato;
  }
  // Una hora que no existe (cambio de horario): se usa el desfase de invierno.
  return new Date(Date.UTC(anio, mes - 1, dia, 0, minutos + 5 * 60));
}

/** Minutos desde la medianoche de un texto "HH:MM"; null si no tiene esa forma. */
export function minutosDeHora(hora: string): number | null {
  const partes = /^(\d{2}):(\d{2})$/.exec(hora);
  if (!partes) return null;
  const horas = Number(partes[1]);
  const minutos = Number(partes[2]);
  return horas < 24 && minutos < 60 ? horas * 60 + minutos : null;
}

/** Instante UTC de una hora local de Nueva York ("HH:MM") en una fecha; null si no es válida. */
export function aInstanteUtc(fecha: string, hora: string): Date | null {
  const minutos = minutosDeHora(hora);
  if (minutos === null || !/^\d{4}-\d{2}-\d{2}$/.test(fecha)) return null;
  return instanteDeNuevaYork(fecha, minutos);
}

function aFecha(fecha: string): Date {
  const [anio, mes, dia] = fecha.split("-").map(Number);
  return new Date(Date.UTC(anio, mes - 1, dia));
}

function aTexto(fecha: Date): string {
  return fecha.toISOString().slice(0, 10);
}

/** La fecha `dias` días después (o antes, si es negativo). */
export function sumarDias(fecha: string, dias: number): string {
  return aTexto(new Date(aFecha(fecha).getTime() + dias * MS_POR_DIA));
}

/**
 * La misma fecha `anios` años antes. El 29 de febrero pasa al 28 si el año destino no es
 * bisiesto.
 */
export function restarAnios(fecha: string, anios: number): string {
  const [anio, mes, dia] = fecha.split("-").map(Number);
  const destino = new Date(Date.UTC(anio - anios, mes - 1, 1));
  const ultimoDia = new Date(Date.UTC(anio - anios, mes, 0)).getUTCDate();
  destino.setUTCDate(Math.min(dia, ultimoDia));
  return aTexto(destino);
}
