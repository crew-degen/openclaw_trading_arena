import { normalizeHistory } from "./chart-utils.js";

let refreshing = false;

const IS_TEST = Boolean(globalThis.__APP_TEST__);
const DEV_MODE = true; // temporary: load dev (non-minified) bundles for debugging
let btcRoot = null;
let btcDataCache = null;
let showingBtc = false;
let visxLibs = null;

async function ensureVisx(){
  if(visxLibs) return visxLibs;
  const dev = DEV_MODE ? "&dev" : "";
  const reactMod = await import(`https://esm.sh/react@18?bundle${dev}`);
  const domMod = await import(`https://esm.sh/react-dom@18/client?bundle${dev}`);
  const shapeMod = await import(`https://esm.sh/@visx/shape@3?bundle${dev}`);
  const React = reactMod.default || reactMod;
  const createRoot = domMod.createRoot || domMod.default?.createRoot;
  const LinePath = shapeMod.LinePath || shapeMod.default?.LinePath;
  visxLibs = { React, createRoot, LinePath };
  return visxLibs;
}

async function fetchJSON(url){
  const r = await fetch(url);
  if(!r.ok) throw new Error('fetch_failed');
  return r.json();
}

function fmt(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  return Number(n).toFixed(2);
}

function fmtPct(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  const v = Number(n);
  const sign = v > 0 ? '+' : '';
  return `${sign}${v.toFixed(2)}%`;
}

function fmt4(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  return Number(n).toFixed(4);
}

function fmt4Pct(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  const v = Number(n);
  const sign = v > 0 ? '+' : '';
  return `${sign}${v.toFixed(4)}%`;
}

function renderPositionField(label, value, cls = ''){
  const valueClass = cls ? `position-value ${cls}` : 'position-value';
  return `<div class="position-field"><span class="position-label">${label}</span><span class="${valueClass}">${value}</span></div>`;
}

function renderPositionCard(pos){
  const asset = pos.asset || '—';
  const direction = pos.direction || '—';
  const upnlCls = (pos.upnl_usd ?? 0) >= 0 ? 'pos' : 'neg';
  const upnlPctCls = (pos.upnl_percent ?? 0) >= 0 ? 'pos' : 'neg';
  return `
    <div class="position-card">
      <div class="position-title">${asset} ${direction}</div>
      <div class="position-grid">
        ${renderPositionField('Asset', asset)}
        ${renderPositionField('Dir', direction)}
        ${renderPositionField('Size', fmt4(pos.size))}
        ${renderPositionField('Size USD', fmt4(pos.size_usd))}
        ${renderPositionField('Entry', fmt4(pos.entry_price))}
        ${renderPositionField('Cur', fmt4(pos.current_price))}
        ${renderPositionField('Oracle', fmt4(pos.oracle_usd))}
        ${renderPositionField('uPnL', fmt4(pos.upnl_usd), upnlCls)}
        ${renderPositionField('uPnL %', fmt4Pct(pos.upnl_percent), upnlPctCls)}
      </div>
    </div>
  `;
}

function renderPositionsBlock(positions){
  if(!positions || positions.length === 0){
    return '<div class="positions-empty">No open positions</div>';
  }
  const cards = positions.map(renderPositionCard).join('');
  return `<div class="positions">${cards}</div>`;
}

function setText(id, text){
  const el = document.getElementById(id);
  if(el) el.textContent = text;
}

function setStatusClass(el, ok){
  if(!el) return;
  el.classList.remove('status-ok','status-bad');
  el.classList.add(ok ? 'status-ok' : 'status-bad');
}

function toggleCharts(showPnl){
  const canvas = document.getElementById('pnlChart');
  const btc = document.getElementById('btcChart');
  const caption = document.getElementById('chart-caption');
  if(showPnl){
    showingBtc = false;
    if(btc) btc.hidden = true;
    if(canvas) canvas.style.display = 'block';
    if(caption) caption.textContent = 'Top agents — P&L curves (last 5 days)';
  } else {
    showingBtc = true;
    if(btc) btc.hidden = false;
    if(canvas) canvas.style.display = 'none';
    if(caption) caption.textContent = 'BTC price (last 24h)';
  }
}

async function loadLeaderboard(){
  const data = await fetchJSON('/api/shuttles/all');
  const rows = (data.shuttles || []).sort((a,b)=> (b.total_pnl||0)-(a.total_pnl||0));
  const top = rows.slice(0,10);
  setText('agent-count', `Agents: ${rows.length}`);

  const topPnl = rows[0]?.total_pnl ?? null;
  const avgPnl = rows.length ? (rows.reduce((s,r)=> s + (r.total_pnl||0), 0) / rows.length) : null;
  setText('top-pnl', `Top PnL: ${fmt(topPnl)}`);
  setText('avg-pnl', `Avg PnL: ${fmt(avgPnl)}`);
  setText('last-updated', `Updated: ${new Date().toUTCString()}`);

  const positionsById = new Map();
  await Promise.all(top.map(async (s) => {
    try {
      const snap = await fetchJSON(`/api/shuttles/${s.id}/snapshot`);
      const positionsRaw = snap.snapshot?.positions || snap.snapshot?.stats || snap.positions || [];
      const positions = (Array.isArray(positionsRaw) ? positionsRaw : []).filter(Boolean);
      positionsById.set(s.id, positions);
    } catch (err) {
      positionsById.set(s.id, []);
    }
  }));

  const tbody = document.getElementById('leaderboardBody');
  tbody.innerHTML = '';
  for(const s of top){
    const tr = document.createElement('tr');
    const label = s.slug?.slice(0,8) || s.id;
    tr.innerHTML = `
      <td>${label}</td>
      <td class="${(s.total_pnl||0) >= 0 ? 'pos' : 'neg'}">${fmt(s.total_pnl)}</td>
      <td>${fmt(s.net_value)}</td>
      <td>${fmt(s.leverage)}</td>
      <td>${fmt(s.health)}</td>
    `;
    tbody.appendChild(tr);

    const positionsRaw = positionsById.get(s.id) || [];
    const order = { BTC: 0, ETH: 1, SOL: 2 };
    const positions = positionsRaw.slice().sort((a, b) => (order[a.asset] ?? 9) - (order[b.asset] ?? 9));
    const posRow = document.createElement('tr');
    posRow.className = 'positions-row';
    const posCell = document.createElement('td');
    posCell.colSpan = 5;
    posCell.innerHTML = renderPositionsBlock(positions);
    posRow.appendChild(posCell);
    tbody.appendChild(posRow);
  }

  return { top, rows };
}

async function loadRoundStatus(){
  const now = new Date();
  const day = now.getUTCDay();
  const isTrading = day >= 2 && day <= 5;
  const label = isTrading ? 'Active trading round' : 'Registration / Break';
  setText('round-status', `${label} · ${now.toUTCString()}`);
}

async function loadHealth(){
  const el = document.getElementById('api-status');
  try {
    const data = await fetchJSON('/api/health');
    const sha = (data.gitSha && data.gitSha !== 'unknown') ? data.gitSha.slice(0,7) : 'n/a';
    const version = data.version || 'unknown';
    setText('api-status', `API: ${version} · ${sha}`);
    setStatusClass(el, data.ok !== false);
  } catch (e) {
    setText('api-status', 'API: unavailable');
    setStatusClass(el, false);
  }
}

async function loadMarket(){
  const data = await fetchJSON('/api/shuttles/prices');
  const prices = data.prices || {};
  const order = ['BTC','ETH','SOL'];
  const tbody = document.getElementById('marketBody');
  tbody.innerHTML = '';

  for(const sym of order){
    const p = prices[sym] || {};
    const pct1h = p.pct_1h ?? null;
    const cls = pct1h > 0 ? 'pos' : pct1h < 0 ? 'neg' : '';
    const rsi = (p.rsi_14 === 0 || p.rsi_14 === null || p.rsi_14 === undefined) ? null : p.rsi_14;
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${sym}</td>
      <td>${fmt(p.price)}</td>
      <td class="${cls}">${fmtPct(pct1h)}</td>
      <td>${fmt(rsi)}</td>
    `;
    tbody.appendChild(tr);
  }
}

async function loadNews(){
  const data = await fetchJSON('/api/shuttles/summaries');
  const list = (data.summaries || []).slice(0,5);
  const ul = document.getElementById('newsBody');
  ul.innerHTML = '';
  for(const s of list){
    const li = document.createElement('li');
    li.innerHTML = `
      <div class="headline">${s.summary || ''}</div>
      <div class="meta">
        <span class="pill">${s.level || 'info'}</span>
        <span>${s.impact || ''}</span>
        <span>${s.confidence ? `conf: ${s.confidence}` : ''}</span>
      </div>
    `;
    ul.appendChild(li);
  }
}

function drawChart(series){
  const canvas = document.getElementById('pnlChart');
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0,0,canvas.width,canvas.height);

  ctx.strokeStyle = '#1a2333';
  for(let i=0;i<5;i++){
    const y = (canvas.height/5)*i;
    ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(canvas.width,y); ctx.stroke();
  }

  const colors = ['#4dd2ff','#9b7bff','#31d0a6','#ffb347','#ff6b6b'];

  const allPoints = series.flat();
  const minY = Math.min(...allPoints.map(p=>p.y));
  const maxY = Math.max(...allPoints.map(p=>p.y));
  const yRange = (maxY - minY) || 1;

  series.forEach((points, idx) => {
    ctx.strokeStyle = colors[idx % colors.length];
    ctx.lineWidth = 2;
    ctx.beginPath();
    points.forEach((p, i) => {
      const x = (canvas.width) * (i/(points.length-1 || 1));
      const y = canvas.height - ((p.y - minY)/yRange) * canvas.height;
      if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
    });
    ctx.stroke();
  });
}

async function loadChart(top){
  const series = [];
  for(const s of top.slice(0,5)){
    const hist = await fetchJSON(`/api/shuttles/${s.id}/history`);
    const points = (hist.snapshots || []).slice(-60).map((snap, i)=>({
      x: i,
      y: snap.total_pnl ?? snap.net_value ?? 0
    }));
    if(points.length) series.push(points);
  }
  if(series.length) drawChart(series);
}


async function renderBtcChart(data){
  const container = document.getElementById('btcChart');
  if(!container || data.length < 2) return;
  const { React, createRoot, LinePath } = await ensureVisx();
  if(!React || !createRoot) throw new Error('react runtime not available');
  const width = Math.max(320, container.clientWidth || 560);
  const height = 320;
  const margin = { top: 24, right: 24, bottom: 24, left: 44 };
  const xMin = data[0].t.getTime();
  const xMax = data[data.length-1].t.getTime();
  const prices = data.map(d => d.price);
  const yMin = Math.min(...prices);
  const yMax = Math.max(...prices);
  const xScale = (t) => {
    const denom = (xMax - xMin) || 1;
    return margin.left + ((t - xMin) / denom) * (width - margin.left - margin.right);
  };
  const yScale = (p) => {
    const denom = (yMax - yMin) || 1;
    return height - margin.bottom - ((p - yMin) / denom) * (height - margin.top - margin.bottom);
  };

  const last = data[data.length - 1];
  const lx = xScale(last.t.getTime());
  const ly = yScale(last.price);
  const lastPrice = last.price;
  const formatted = lastPrice?.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const labelText = `BTC / $${formatted}`;
  const badgeH = 18;
  const badgeW = Math.max(80, 6 * labelText.length);
  let bx = lx + 8;
  if (bx + badgeW > width - margin.right) bx = lx - badgeW - 8;
  const by = Math.max(margin.top, Math.min(ly - badgeH / 2, height - margin.bottom - badgeH));

  if(!btcRoot) btcRoot = createRoot(container);
  const pointsStr = data.map(d => `${xScale(d.t.getTime())},${yScale(d.price)}`).join(' ');
  const lineEl = LinePath
    ? React.createElement(LinePath, {
        data,
        x: d => xScale(d.t.getTime()),
        y: d => yScale(d.price),
        stroke: '#f5d547',
        strokeWidth: 1
      })
    : React.createElement('polyline', {
        points: pointsStr,
        fill: 'none',
        stroke: '#f5d547',
        strokeWidth: 1
      });

  const svg = React.createElement('svg', { width, height },
    lineEl,
    React.createElement('rect', {
      x: bx, y: by, width: badgeW, height: badgeH,
      rx: 8, ry: 8, fill: '#1f2a3a', stroke: '#f5d547'
    }),
    React.createElement('text', { x: bx + badgeW/2, y: by + badgeH/2 + 4, fill: '#f5d547', fontSize: 10, textAnchor: 'middle' }, labelText),
    React.createElement('text', { x: width - 6, y: height/2, fill: '#8b97a7', fontSize: 12, textAnchor: 'middle', transform: `rotate(90 ${width - 6} ${height/2})` }, 'BTC Price')
  );
  btcRoot.render(svg);
}

async function loadBtcChart(){
  try {
    const raw = await fetchJSON('/api/shuttles/price-history?ticker=BTC&hours=24&limit=1000');
    const data = normalizeHistory(raw);
    if(!data.length) return;
    btcDataCache = data;
    await renderBtcChart(data);
  } catch (e) {
    console.error(e);
  }
}

async function refreshAll(includeChart = false){
  if(refreshing) return;
  refreshing = true;
  try {
    await loadRoundStatus();
    await loadHealth();
    const { top, rows } = await loadLeaderboard();
    await Promise.all([loadMarket(), loadNews()]);

    if(rows.length === 0){
      toggleCharts(false);
      await loadBtcChart();
    } else {
      toggleCharts(true);
      if(includeChart) await loadChart(top);
    }
  } catch (e){
    console.error(e);
  } finally {
    refreshing = false;
  }
}

if(!IS_TEST && typeof window !== 'undefined'){
  window.addEventListener('resize', () => {
    if(showingBtc && btcDataCache) renderBtcChart(btcDataCache);
  });

  (async function init(){
    await refreshAll(true);
    setInterval(() => refreshAll(false), 30000);
    setInterval(() => refreshAll(true), 120000);
  })();
}

export { fmt, fmtPct, drawChart, normalizeHistory };
