// ── Session ──────────────────────────────────────────────────────────────────
let SESSION_ID = localStorage.getItem('docchat_session') || crypto.randomUUID();
localStorage.setItem('docchat_session', SESSION_ID);

// ── State ─────────────────────────────────────────────────────────────────────
let docLoaded = false;
let isAsking = false;

// ── DOM refs ─────────────────────────────────────────────────────────────────
const $ = id => document.getElementById(id);
const messagesEl = $('messages');
const chatInput = $('chat-input');
const sendBtn = $('send-btn');

// ── Toast ────────────────────────────────────────────────────────────────────
function toast(msg, type = 'info', duration = 3500) {
  const icons = { success: '✅', error: '❌', info: 'ℹ️' };
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = `<span>${icons[type]}</span><span>${msg}</span>`;
  $('toast-container').appendChild(el);
  setTimeout(() => {
    el.style.animation = 'fadeOut .3s ease forwards';
    setTimeout(() => el.remove(), 300);
  }, duration);
}

// ── Chip helper ───────────────────────────────────────────────────────────────
function chip(icon, label) {
  return `<span class="chip">${icon} ${label}</span>`;
}

// ── Tab switching ─────────────────────────────────────────────────────────────
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const tab = btn.dataset.tab;
    document.querySelectorAll('.tab-panel').forEach(p => {
      p.classList.remove('active');
      p.style.display = 'none';
    });
    const panel = $(`panel-${tab}`);
    if (panel) { panel.style.display = 'flex'; panel.classList.add('active'); }
    if (tab === 'browser') loadBrowser();
  });
});

// ── Sidebar toggle ────────────────────────────────────────────────────────────
$('sidebar-toggle').addEventListener('click', () => {
  document.querySelector('.sidebar').classList.toggle('collapsed');
});

// ── Load models ───────────────────────────────────────────────────────────────
let _allModels = {};

async function loadModels() {
  try {
    const res = await fetch('/api/models');
    const data = await res.json();
    _allModels = data.models;
    const providerEl = $('provider-select');
    const providers = Object.keys(data.models);
    providerEl.innerHTML = providers.map(p => `<option value="${p}">${p}</option>`).join('');
    const defaultProvider = providers.find(p => p === 'GitHub Copilot') || providers[0];
    providerEl.value = defaultProvider;
    updateModels(data.models);
    providerEl.addEventListener('change', () => updateModels(data.models));
  } catch (e) { console.error('Failed to load models', e); }
}

function updateModels(allModels) {
  const provider = $('provider-select').value;
  const models = allModels[provider] || [];
  const modelEl = $('model-select');
  modelEl.innerHTML = models.map(m => `<option value="${m}">${m}</option>`).join('');
  const preferred = models.find(m => m.includes('haiku')) || models[0];
  if (preferred) modelEl.value = preferred;
}

loadModels();

// ── Token detection ───────────────────────────────────────────────────────────
async function detectToken() {
  try {
    const res = await fetch('/api/token');
    const data = await res.json();
    if (data.token) {
      $('github-token').value = data.token;
      $('token-status').innerHTML = '<span class="token-ok">🔑 Token auto-detected</span>';
    } else {
      $('token-status').innerHTML = '<span class="token-err">⚠️ Run: gh auth login</span>';
    }
  } catch (e) {
    $('token-status').innerHTML = '<span class="token-err">⚠️ Could not detect token</span>';
  }
}
detectToken();

// ── Top-K slider ──────────────────────────────────────────────────────────────
$('topk').addEventListener('input', e => { $('topk-val').textContent = e.target.value; });

// ── File upload ───────────────────────────────────────────────────────────────
const fileInput = $('file-input');
const uploadZone = $('upload-zone');

$('btn-upload-trigger').addEventListener('click', () => fileInput.click());
uploadZone.addEventListener('click', e => {
  if (e.target !== $('btn-upload-trigger')) fileInput.click();
});

uploadZone.addEventListener('dragover', e => { e.preventDefault(); uploadZone.classList.add('drag-over'); });
uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('drag-over'));
uploadZone.addEventListener('drop', e => {
  e.preventDefault();
  uploadZone.classList.remove('drag-over');
  const f = e.dataTransfer.files[0];
  if (f) handleFile(f);
});

fileInput.addEventListener('change', e => {
  const f = e.target.files[0];
  if (f) handleFile(f);
});

async function handleFile(file) {
  const token = $('github-token').value.trim();
  if (!token) { toast('Please enter a GitHub token first', 'error'); return; }

  uploadZone.style.display = 'none';
  $('progress-box').style.display = 'block';
  $('progress-title').textContent = `Processing ${file.name}`;

  const steps = [
    [15, '🔍 Reading file…'],
    [35, '📑 Parsing pages…'],
    [55, '🔢 Generating embeddings…'],
    [80, '🗂️ Indexing vectors in ChromaDB…'],
  ];

  let stepIdx = 0;
  const stepInterval = setInterval(() => {
    if (stepIdx < steps.length) {
      const [pct, msg] = steps[stepIdx++];
      setProgress(pct, msg);
    }
  }, 600);

  try {
    const fd = new FormData();
    fd.append('session_id', SESSION_ID);
    fd.append('file', file);
    fd.append('model', $('model-select').value);
    fd.append('provider', $('provider-select').value);
    fd.append('github_token', token);
    fd.append('top_k', $('topk').value);

    const res = await fetch('/api/upload', { method: 'POST', body: fd });
    clearInterval(stepInterval);

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || 'Upload failed');
    }
    const data = await res.json();

    setProgress(100, '✅ Ready!');
    await new Promise(r => setTimeout(r, 600));

    onDocLoaded(data);
    toast(`✅ ${data.stats.total_pages} pages · ${data.stats.total_words.toLocaleString()} words indexed`, 'success');

  } catch (e) {
    clearInterval(stepInterval);
    $('progress-box').style.display = 'none';
    uploadZone.style.display = 'block';
    toast(`❌ ${e.message}`, 'error');
  }
}

function setProgress(pct, msg) {
  $('progress-fill').style.width = pct + '%';
  $('progress-msg').textContent = msg;
}

function onDocLoaded(data) {
  docLoaded = true;
  const stats = data.stats;

  $('panel-welcome').style.display = 'none';
  $('panel-welcome').classList.remove('active');
  $('tabbar').style.display = 'flex';

  showTab('chat');

  $('topbar-title').textContent = data.filename;
  $('topbar-badges').innerHTML = `
    <span class="badge">${stats.total_pages} pages · ${stats.total_words.toLocaleString()} words</span>
    <span class="badge accent">🤖 ${$('model-select').value}</span>
  `;

  $('doc-name').textContent = data.filename;
  $('doc-chips').innerHTML = `
    ${chip('📑', `${stats.total_pages} pages`)}
    ${chip('📝', `${stats.total_words.toLocaleString()} words`)}
    ${chip('⚡', `${stats.avg_words_per_page}w/page`)}
  `;
  $('doc-info').style.display = 'block';

  messagesEl.innerHTML = `
    <div class="chat-empty">
      <div class="ce-icon">💬</div>
      <div class="ce-title">Ask anything about <strong>${escapeHtml(data.filename)}</strong></div>
      <div class="ce-sub">Multi-turn supported — follow up freely</div>
    </div>
  `;
}

function showTab(tab) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  document.querySelectorAll('.tab-panel').forEach(p => { p.style.display = 'none'; p.classList.remove('active'); });
  const panel = $(`panel-${tab}`);
  if (panel) { panel.style.display = 'flex'; panel.classList.add('active'); }
}

// ── New Chat ──────────────────────────────────────────────────────────────────
$('btn-new-chat').addEventListener('click', async () => {
  await fetch('/api/reset', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ session_id: SESSION_ID }),
  });
  docLoaded = false;
  $('tabbar').style.display = 'none';
  $('doc-info').style.display = 'none';
  $('topbar-title').textContent = 'VectorRAG — Semantic Search';
  $('topbar-badges').innerHTML = '';
  document.querySelectorAll('.tab-panel').forEach(p => { p.style.display = 'none'; p.classList.remove('active'); });
  $('panel-welcome').style.display = 'flex';
  $('panel-welcome').classList.add('active');
  uploadZone.style.display = 'block';
  $('progress-box').style.display = 'none';
  fileInput.value = '';
  messagesEl.innerHTML = '';
  $('sources-content').innerHTML = '<div class="sources-empty">Ask a question to see which pages were retrieved</div>';
  toast('New chat started', 'info');
});

// ── Clear Chat ────────────────────────────────────────────────────────────────
$('btn-clear-chat').addEventListener('click', async () => {
  await fetch('/api/clear_chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ session_id: SESSION_ID }),
  });
  messagesEl.innerHTML = `
    <div class="chat-empty">
      <div class="ce-icon">💬</div>
      <div class="ce-title">Chat cleared — ask a new question</div>
    </div>
  `;
  $('sources-content').innerHTML = '<div class="sources-empty">Ask a question to see which pages were retrieved</div>';
  toast('Chat history cleared', 'success');
});

// ── Chat submit ───────────────────────────────────────────────────────────────
async function submitChat() {
  if (!docLoaded || isAsking) return;
  const question = chatInput.value.trim();
  if (!question) return;

  const emptyEl = messagesEl.querySelector('.chat-empty');
  if (emptyEl) emptyEl.remove();

  chatInput.value = '';
  chatInput.style.height = 'auto';
  isAsking = true;
  sendBtn.disabled = true;

  appendMessage('user', question);

  const typingId = 'typing-' + Date.now();
  messagesEl.insertAdjacentHTML('beforeend', `
    <div class="msg-row assistant" id="${typingId}">
      <div class="avatar assistant">AI</div>
      <div class="bubble assistant">
        <div class="typing"><span></span><span></span><span></span></div>
      </div>
    </div>
  `);
  scrollToBottom();

  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: SESSION_ID, question }),
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || 'Chat failed');
    }
    const data = await res.json();

    document.getElementById(typingId)?.remove();
    appendMessage('assistant', data.answer, data.sources);

    renderSources(data.sources, question);

    const accentBadge = $('topbar-badges').querySelector('.accent');
    if (accentBadge) accentBadge.textContent = `🤖 ${$('model-select').value}`;

    toast('Answer generated', 'success', 2000);

  } catch (e) {
    document.getElementById(typingId)?.remove();
    appendMessage('assistant', `❌ Error: ${e.message}`);
    toast(e.message.slice(0, 80), 'error');
  } finally {
    isAsking = false;
    sendBtn.disabled = false;
    scrollToBottom();
  }
}

sendBtn.addEventListener('click', submitChat);
chatInput.addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submitChat(); }
});

chatInput.addEventListener('input', () => {
  chatInput.style.height = 'auto';
  chatInput.style.height = Math.min(chatInput.scrollHeight, 160) + 'px';
});

function appendMessage(role, text, sources = []) {
  const div = document.createElement('div');
  div.className = `msg-row ${role}`;
  const avatar = role === 'user'
    ? '<div class="avatar user">U</div>'
    : '<div class="avatar assistant">AI</div>';
  const content = role === 'assistant' ? marked.parse(text) : escapeHtml(text);
  div.innerHTML = `
    ${role === 'user' ? '' : avatar}
    <div class="bubble ${role}">${content}</div>
    ${role === 'user' ? avatar : ''}
  `;
  messagesEl.appendChild(div);

  if (role === 'assistant' && sources.length > 0) {
    const cited = sources.slice(0, 3).map(s => `p.${s.page_num} — ${s.title.slice(0, 30)}`).join(', ');
    const fn = document.createElement('div');
    fn.className = 'source-footnote';
    fn.textContent = `📎 Retrieved: ${cited}`;
    messagesEl.appendChild(fn);
  }
  scrollToBottom();
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function scrollToBottom() {
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

// ── Sources panel ─────────────────────────────────────────────────────────────
function renderSources(sources, query) {
  if (!sources || sources.length === 0) {
    $('sources-content').innerHTML = '<div class="sources-empty">No sources retrieved</div>';
    return;
  }
  const maxScore = sources[0]?.score || 1;
  $('sources-content').innerHTML = sources.map((s, i) => {
    const pct = maxScore > 0 ? Math.round(s.score / maxScore * 100) : 0;
    const cardId = `sc-${i}`;
    return `
      <div class="source-card">
        <div class="source-card-header" onclick="toggleCard('${cardId}')">
          <span class="sc-rank">#${i + 1}</span>
          <span class="sc-title">${escapeHtml(s.title)}</span>
          <span class="sc-pct">${pct}%</span>
        </div>
        <div class="source-card-body" id="${cardId}">
          <div class="sc-chips">
            ${chip('📄', `page ${s.page_num}`)}
            ${chip('📝', `${s.word_count}w`)}
            ${chip('🏷️', s.source_type)}
            ${chip('📊', `Sim: ${s.score.toFixed(3)}`)}
          </div>
          <div class="sc-preview">${escapeHtml(s.content_preview)}</div>
        </div>
      </div>
    `;
  }).join('');
}

function toggleCard(id) {
  const el = $(id);
  if (el) el.classList.toggle('open');
}

// ── Document Browser ──────────────────────────────────────────────────────────
async function loadBrowser() {
  if (!docLoaded) return;
  $('browser-stats').innerHTML = '';
  $('browser-count').textContent = '';
  $('pages-list').innerHTML = '<div class="browser-loading">⏳ Loading pages…</div>';

  const search = $('browser-search').value.trim();
  const url = `/api/pages?session_id=${SESSION_ID}${search ? '&search=' + encodeURIComponent(search) : ''}`;
  try {
    const res = await fetch(url);
    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || `HTTP ${res.status}`);
    renderBrowser(data);
  } catch (e) {
    $('pages-list').innerHTML = `<div class="browser-loading">❌ ${escapeHtml(e.message)}</div>`;
    toast('Failed to load pages', 'error');
  }
}

function renderBrowser(data) {
  const stats = data.stats;
  $('browser-stats').innerHTML = `
    <div class="stat-card"><div class="stat-val">${stats.total_pages}</div><div class="stat-lbl">📄 Pages</div></div>
    <div class="stat-card"><div class="stat-val">${stats.total_words.toLocaleString()}</div><div class="stat-lbl">📝 Words</div></div>
    <div class="stat-card"><div class="stat-val">${stats.avg_words_per_page}</div><div class="stat-lbl">⚡ Avg Words</div></div>
    <div class="stat-card"><div class="stat-val">${stats.source_types.length}</div><div class="stat-lbl">🗂️ Types</div></div>
  `;
  $('browser-count').textContent = `${data.pages.length} pages shown`;

  $('pages-list').innerHTML = data.pages.map((p, i) => {
    const bodyId = `pb-${i}`;
    const scoreLabel = p.score > 0 ? `  ·  Sim ${p.score.toFixed(3)}` : '';
    const isMarkdown = p.source_type === 'xlsx_sheet' || p.source_type === 'csv_batch' || p.source_type === 'md_section';
    const contentHtml = isMarkdown
      ? `<div class="page-content-md">${marked.parse(p.content)}</div>`
      : `<pre class="page-content">${escapeHtml(p.content)}</pre>`;
    return `
      <div class="page-item" id="pi-${i}">
        <div class="page-header" onclick="togglePage(${i})">
          <span class="page-num">${p.page_num}.</span>
          <span class="page-title">${escapeHtml(p.title)}${escapeHtml(scoreLabel)}</span>
          <span class="page-chevron">›</span>
        </div>
        <div class="page-body" id="${bodyId}">
          <div class="page-chips">
            ${chip('📝', `${p.word_count} words`)}
            ${chip('🏷️', p.source_type)}
            ${chip('📄', `page ${p.page_num}`)}
          </div>
          ${contentHtml}
        </div>
      </div>
    `;
  }).join('');
}

function togglePage(i) {
  const item = $(`pi-${i}`);
  const body = $(`pb-${i}`);
  if (item && body) {
    item.classList.toggle('open');
    body.style.display = item.classList.contains('open') ? 'block' : 'none';
  }
}

// Browser search with debounce
let browserSearchTimer;
$('browser-search').addEventListener('input', () => {
  clearTimeout(browserSearchTimer);
  browserSearchTimer = setTimeout(loadBrowser, 400);
});
