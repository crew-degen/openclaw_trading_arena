export function normalizeHistory(raw){
  let arr = raw?.ticks || raw?.history || raw?.prices || raw?.data || raw?.items || raw;
  if(arr && arr.BTC) arr = arr.BTC;
  if(!Array.isArray(arr)) return [];
  return arr.map(d => {
    let t = d.timestamp ?? d.ts ?? d.time ?? d.t ?? d.datetime ?? d.date ?? d.created_at ?? d.createdAt;
    const price = d.price ?? d.p ?? d.close ?? d.value;
    if(t === undefined || price === undefined) return null;
    if(typeof t === 'number' && t < 1e12) t = t * 1000;
    const dt = new Date(t);
    return { t: dt, price: Number(price) };
  }).filter(Boolean).sort((a,b)=>a.t-b.t);
}
