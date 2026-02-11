import { normalizeHistory } from "./chart-utils.js";

let refreshing = false;

const IS_TEST = Boolean(globalThis.__APP_TEST__);
const DEV_MODE = true; // temporary: load dev (non-minified) bundles for debugging
let btcRoot = null;
let btcDataCache = null;
let showingBtc = false;
let visxLibs = null;
let roundTimerId = null;
let roundTimerEnd = null;

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

function fmtSigned(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  const v = Number(n);
  const sign = v > 0 ? '+' : '';
  return `${sign}${v.toFixed(2)}`;
}

function fmtNetValue(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  return `~$${Number(n).toFixed(2)}`;
}

function fmtLeverage(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  return `x${Number(n).toFixed(2)}`;
}

function fmtHealth(n){
  if(n === null || n === undefined || Number.isNaN(n)) return '—';
  return `${Math.round(Number(n))}%`;
}

function fmtLaunched(ts){
  if(!ts) return '—';
  const d = new Date(ts);
  if(Number.isNaN(d.getTime())) return '—';
  const iso = d.toISOString();
  return `${iso.slice(5, 10)} ${iso.slice(11, 16)} UTC`;
}

function renderPositionField(label, value, cls = ''){
  const valueClass = cls ? `position-value ${cls}` : 'position-value';
  return `<div class="position-field"><span class="position-label">${label}</span><span class="${valueClass}">${value}</span></div>`;
}

function renderPositionCard(pos){
  const asset = pos.asset || '—';
  const direction = pos.direction || '—';
  const dirIcon = direction === 'LONG' ? '↑' : direction === 'SHORT' ? '↓' : '';
  const dirClass = direction === 'LONG' ? 'dir-long' : direction === 'SHORT' ? 'dir-short' : '';
  const dirBadge = dirIcon ? `<span class="dir-icon ${dirClass}">${dirIcon}</span>` : '';
  const upnlCls = (pos.upnl_usd ?? 0) >= 0 ? 'pos' : 'neg';
  const upnlPctCls = (pos.upnl_percent ?? 0) >= 0 ? 'pos' : 'neg';
  return `
    <div class="position-card">
      <div class="position-title">${asset} ${dirBadge} ${direction}</div>
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
  return `
    <div class="positions-wrap">
      <div class="positions-label">Open Positions</div>
      <div class="positions">${cards}</div>
    </div>
  `;
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

function formatCountdown(ms){
  const totalMs = Math.max(0, Math.floor(ms));
  const days = Math.floor(totalMs / 86400000);
  const hours = Math.floor((totalMs % 86400000) / 3600000);
  const mins = Math.floor((totalMs % 3600000) / 60000);
  const secs = Math.floor((totalMs % 60000) / 1000);
  const cs = Math.floor((totalMs % 1000) / 10);
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(days)}:${pad(hours)}:${pad(mins)}:${pad(secs)}:${pad(cs)}`;
}

function setRoundTimer(endTime, status){
  const el = document.getElementById('round-timer');
  if(!el) return;
  const valueEl = el.querySelector('.round-timer-value');
  if(status !== 'active' || !endTime){
    el.hidden = true;
    if(roundTimerId){
      clearInterval(roundTimerId);
      roundTimerId = null;
    }
    roundTimerEnd = null;
    return;
  }
  const endMs = new Date(endTime).getTime();
  if(Number.isNaN(endMs)){
    el.hidden = true;
    return;
  }
  roundTimerEnd = endMs;
  el.hidden = false;
  const tick = () => {
    const diff = roundTimerEnd - Date.now();
    if(valueEl) valueEl.textContent = formatCountdown(diff);
  };
  tick();
  if(roundTimerId) clearInterval(roundTimerId);
  roundTimerId = setInterval(tick, 100);
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
  const decisionById = new Map();
  await Promise.all(top.map(async (s) => {
    try {
      const snap = await fetchJSON(`/api/shuttles/${s.id}/snapshot`);
      const positionsRaw = snap.snapshot?.positions || snap.snapshot?.stats || snap.positions || [];
      const positions = (Array.isArray(positionsRaw) ? positionsRaw : []).filter(Boolean);
      positionsById.set(s.id, positions);
    } catch (err) {
      positionsById.set(s.id, []);
    }

    try {
      const dec = await fetchJSON(`/api/shuttles/${s.id}/decisions`);
      const latest = (dec.decisions || [])[0];
      decisionById.set(s.id, latest?.rationale || '');
    } catch (err) {
      decisionById.set(s.id, '');
    }
  }));

  const tbody = document.getElementById('leaderboardBody');
  tbody.innerHTML = '';
  for(const s of top){
    const tr = document.createElement('tr');
    tr.className = 'leader-row';
    const label = s.slug?.slice(0,8) || s.id;
    tr.innerHTML = `
      <td>${label}</td>
      <td>${fmtLaunched(s.created_at)}</td>
      <td class="${(s.total_pnl||0) >= 0 ? 'pos' : 'neg'}">${fmtSigned(s.total_pnl)}</td>
      <td>${fmtNetValue(s.net_value)}</td>
      <td>${fmtLeverage(s.leverage)}</td>
      <td>${fmtHealth(s.health)}</td>
    `;
    tbody.appendChild(tr);

    const positionsRaw = positionsById.get(s.id) || [];
    const order = { BTC: 0, ETH: 1, SOL: 2 };
    const positions = positionsRaw.slice().sort((a, b) => (order[a.asset] ?? 9) - (order[b.asset] ?? 9));
    const posRow = document.createElement('tr');
    posRow.className = 'positions-row';
    const posCell = document.createElement('td');
    posCell.colSpan = 6;
    posCell.innerHTML = renderPositionsBlock(positions);
    posRow.appendChild(posCell);
    tbody.appendChild(posRow);

    const rationale = (decisionById.get(s.id) || '').trim();
    const decRow = document.createElement('tr');
    decRow.className = 'decision-row';
    const decCell = document.createElement('td');
    decCell.colSpan = 6;
    const decisionText = rationale || 'No recent decision';
    const safe = decisionText.replace(/"/g, '&quot;');
    decCell.innerHTML = `
      <div class="decision-line">
        <span class="decision-badge">DECISION</span>
        <span class="decision-text" data-text="${safe}"></span>
      </div>
    `;
    decRow.appendChild(decCell);
    tbody.appendChild(decRow);
  }

  return { top, rows };
}

async function loadRoundStatus(){
  try {
    const data = await fetchJSON('/api/rounds/status');
    const status = data.status || 'unknown';
    const now = new Date();
    const label = status === 'active'
      ? 'Active trading round'
      : status === 'registration'
      ? 'Registration open'
      : status === 'break'
      ? 'Break'
      : 'Round status';
    setText('round-status', `${label} · ${now.toUTCString()}`);
    setRoundTimer(data.endTime, status);
  } catch (e) {
    const now = new Date();
    setText('round-status', `Round status · ${now.toUTCString()}`);
    setRoundTimer(null, '');
  }
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
  const row = document.getElementById('marketStrip');
  if(!row) return;
  row.innerHTML = '';

  for(const sym of order){
    const p = prices[sym] || {};
    const pct1h = p.pct_1h ?? null;
    const cls = pct1h > 0 ? 'pos' : pct1h < 0 ? 'neg' : '';
    const rsi = (p.rsi_14 === 0 || p.rsi_14 === null || p.rsi_14 === undefined) ? null : p.rsi_14;
    const item = document.createElement('div');
    item.className = 'strip-item';
    item.innerHTML = `
      <div class="strip-line">
        <span class="strip-sym">${sym}</span>
        <span class="strip-price">${fmt(p.price)}</span>
        <span class="strip-pct ${cls}">${fmtPct(pct1h)}</span>
        <span class="strip-rsi">${rsi === null ? 'RSI —' : `RSI ${fmt(rsi)}`}</span>
      </div>
    `;
    row.appendChild(item);
  }
}

function fmtDecisionTime(ts){
  if(!ts) return '--:-- --.--.--';
  const d = new Date(ts);
  if(Number.isNaN(d.getTime())) return '--:-- --.--.--';
  const pad = (n) => String(n).padStart(2, '0');
  const hh = pad(d.getUTCHours());
  const mm = pad(d.getUTCMinutes());
  const dd = pad(d.getUTCDate());
  const mo = pad(d.getUTCMonth() + 1);
  const yy = d.getUTCFullYear();
  return `${hh}:${mm} ${dd}-${mo}-${yy}`;
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

async function loadFeed(){
  const feedEl = document.getElementById('feedBody');
  if(!feedEl) return;
  feedEl.innerHTML = '';
  try {
    const data = await fetchJSON('/api/shuttles/all');
    const shuttles = data.shuttles || [];
    const decisions = [];

    await Promise.all(shuttles.map(async (s) => {
      try {
        const dec = await fetchJSON(`/api/shuttles/${s.id}/decisions`);
        const list = dec.decisions || [];
        list.forEach((d) => {
          decisions.push({
            agent: s.slug?.slice(0,8) || s.id,
            created_at: d.created_at,
            asset: d.asset,
            action: d.action,
            quantity: d.quantity,
            rationale: d.rationale,
          });
        });
      } catch (err) {
        // skip failures
      }
    }));

    decisions.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    const top = decisions.slice(0, 50);

    const assetIcons = {
      BTC: 'https://s2.coinmarketcap.com/static/img/coins/64x64/1.png',
      ETH: 'https://s2.coinmarketcap.com/static/img/coins/64x64/1027.png',
      SOL: 'https://s2.coinmarketcap.com/static/img/coins/64x64/5426.png'
    };
    const gifs = {
      BUY: 'https://media.tenor.com/2y5xY0mCsgwAAAAC/rocket-launch.gif',
      SELL: 'https://media.tenor.com/9y7m-1sK3xIAAAAC/this-is-fine-dog.gif'
    };

    top.forEach((d) => {
      const li = document.createElement('li');
      const action = d.action || 'WAIT';
      const asset = d.asset || '';
      const qty = d.quantity ? `${Number(d.quantity).toFixed(4)} ${asset}` : '';
      const actionClass = action === 'BUY' ? 'feed-buy' : action === 'SELL' ? 'feed-sell' : 'feed-wait';
      const bgClass = action === 'BUY' ? 'feed-buy-bg' : action === 'SELL' ? 'feed-sell-bg' : '';
      li.className = `feed-item ${bgClass}`.trim();
      const icon = assetIcons[asset];
      const gif = (action === 'BUY' || action === 'SELL') ? gifs[action] : '';
      li.innerHTML = `
        <div class="feed-row">
          <div class="feed-head">
            <span class="feed-agent">${d.agent}</span>
            <span class="feed-time">${fmtDecisionTime(d.created_at)}</span>
          </div>
          <div class="feed-meta">
            <span class="feed-action ${actionClass}">${action}</span>
            ${asset ? `<span class="feed-asset">${icon ? `<img class="asset-icon" src="${icon}" alt="${asset}" />` : ''}${asset}</span>` : ''}
            ${qty ? `<span class="feed-qty">${qty}</span>` : ''}
            ${gif ? `<img class="feed-gif" src="${gif}" alt="${action}" loading="lazy" referrerpolicy="no-referrer" />` : ''}
          </div>
          <div class="feed-rationale">${d.rationale || ''}</div>
        </div>
      `;
      feedEl.appendChild(li);
    });
  } catch (err) {
    const li = document.createElement('li');
    li.textContent = 'Feed unavailable';
    feedEl.appendChild(li);
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

function applyTypingEffect(){
  const nodes = document.querySelectorAll('.decision-text');
  nodes.forEach(node => {
    if(node.dataset.typing === '1') return;
    node.dataset.typing = '1';
    const full = node.dataset.text || '';
    let i = 0;
    const tick = () => {
      node.textContent = full.slice(0, i);
      i = (i + 1) % (full.length + 1);
      const delay = i === 0 ? 800 : 40;
      node._typingTimer = setTimeout(tick, delay);
    };
    tick();
  });
}

async function refreshAll(includeChart = false){
  if(refreshing) return;
  refreshing = true;
  try {
    await loadRoundStatus();
    await loadHealth();
    const { top, rows } = await loadLeaderboard();
    await Promise.all([loadMarket(), loadNews(), loadFeed()]);
    applyTypingEffect();

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
