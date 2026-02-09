let refreshing = false;

async function fetchJSON(url){
  const r = await fetch(url);
  if(!r.ok) throw new Error('fetch_failed');
  return r.json();
}

function fmt(n){
  if(n === null || n === undefined) return '—';
  return Number(n).toFixed(2);
}

function fmtPct(n){
  if(n === null || n === undefined) return '—';
  const v = Number(n);
  const sign = v > 0 ? '+' : '';
  return `${sign}${v.toFixed(2)}%`;
}

function setText(id, text){
  const el = document.getElementById(id);
  if(el) el.textContent = text;
}

async function loadLeaderboard(){
  const data = await fetchJSON('/api/shuttles/all');
  const rows = (data.shuttles || []).sort((a,b)=> (b.total_pnl||0)-(a.total_pnl||0));
  const top = rows.slice(0,10);
  setText('agent-count', `Agents: ${rows.length}`);

  // stats
  const topPnl = rows[0]?.total_pnl ?? null;
  const avgPnl = rows.length ? (rows.reduce((s,r)=> s + (r.total_pnl||0), 0) / rows.length) : null;
  setText('top-pnl', `Top PnL: ${fmt(topPnl)}`);
  setText('avg-pnl', `Avg PnL: ${fmt(avgPnl)}`);
  setText('last-updated', `Updated: ${new Date().toUTCString()}`);

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
  }

  return top;
}

async function loadRoundStatus(){
  const now = new Date();
  const day = now.getUTCDay(); // 1=Mon
  const isTrading = day >= 2 && day <= 5; // Tue-Fri
  const label = isTrading ? 'Active trading round' : 'Registration / Break';
  setText('round-status', `${label} · ${now.toUTCString()}`);
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

  // background grid
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

async function refreshAll(includeChart = false){
  if(refreshing) return;
  refreshing = true;
  try {
    await loadRoundStatus();
    const top = await loadLeaderboard();
    await Promise.all([loadMarket(), loadNews()]);
    if(includeChart) await loadChart(top);
  } catch (e){
    console.error(e);
  } finally {
    refreshing = false;
  }
}

(async function init(){
  await refreshAll(true);
  setInterval(() => refreshAll(false), 30000);
  setInterval(() => refreshAll(true), 120000);
})();
