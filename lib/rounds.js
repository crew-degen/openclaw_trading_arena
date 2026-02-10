export function getWeekStartUTC(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay(); // 0 Sun, 1 Mon
  const diff = (day === 0 ? -6 : 1 - day);
  d.setUTCDate(d.getUTCDate() + diff);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

export function getRoundWindow(date = new Date(), closeHourUtc = 18) {
  const monday = getWeekStartUTC(date);
  const activeStart = new Date(monday);
  activeStart.setUTCDate(monday.getUTCDate() + 1); // Tue 00:00

  const activeEnd = new Date(monday);
  activeEnd.setUTCDate(monday.getUTCDate() + 4); // Fri
  activeEnd.setUTCHours(closeHourUtc, 0, 0, 0);

  return { monday, activeStart, activeEnd };
}

export function computeRoundStatus(date = new Date(), closeHourUtc = 18) {
  const day = date.getUTCDay();
  if (day === 1) return "registration"; // Monday
  if (day >= 2 && day <= 4) return "active"; // Tue-Thu
  if (day === 5) return date.getUTCHours() < closeHourUtc ? "active" : "closed"; // Fri
  if (day === 6 || day === 0) return "break"; // Sat/Sun
  return "registration";
}
