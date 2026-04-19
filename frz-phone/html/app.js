// FRZ Phone NUI
(() => {
  const resourceName = (window.GetParentResourceName && GetParentResourceName()) || 'frz-phone';

  const root = document.getElementById('root');
  const phoneEl = document.getElementById('phone');
  const timeEl = document.getElementById('time');
  const toast = document.getElementById('toast');

  let state = { number: null, os: 'iphone', contacts: [], callLog: [], conversations: [], bank: { balance: 0, transactions: [] } };
  let apps = [];
  let dialerBuffer = '';
  let currentConvo = null;  // number

  // ------ helpers ------
  function post(endpoint, body) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    }).catch(() => {});
  }
  // Safe DOM builder : construit un element avec textContent uniquement (pas d'interpolation de HTML).
  function h(tag, opts, ...children) {
    const el = document.createElement(tag);
    opts = opts || {};
    if (opts.class) el.className = opts.class;
    if (opts.text !== undefined) el.textContent = opts.text;
    if (opts.data) for (const k in opts.data) el.dataset[k] = opts.data[k];
    if (opts.attrs) for (const k in opts.attrs) el.setAttribute(k, opts.attrs[k]);
    if (opts.style) el.setAttribute('style', opts.style);
    if (opts.on) for (const k in opts.on) el.addEventListener(k, opts.on[k]);
    for (const c of children) {
      if (c == null) continue;
      if (typeof c === 'string') el.appendChild(document.createTextNode(c));
      else el.appendChild(c);
    }
    return el;
  }
  function clear(el) { while (el.firstChild) el.removeChild(el.firstChild); }
  function showView(id) {
    document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
    document.getElementById(id).classList.remove('hidden');
  }
  let toastTimer = null;
  function showToast(msg, type) {
    toast.textContent = msg;
    toast.className = `toast ${type || ''}`;
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.add('hidden'), 2500);
    toast.classList.remove('hidden');
  }
  function fmtEur(n) {
    return (Number(n) || 0).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' €';
  }
  function fmtTime(ts) {
    const d = new Date((ts || 0) * 1000);
    return d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  }
  function fmtCardNumber(seed) {
    const s = (seed || '').replace(/\D/g, '').slice(-4).padStart(4, '•');
    return `•••• •••• •••• ${s}`;
  }

  // ------ time ticker ------
  function tickTime() {
    const d = new Date();
    timeEl.textContent = d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  }
  setInterval(tickTime, 15000);
  tickTime();

  // ------ rendering ------
  function renderHome() {
    const grid = document.getElementById('app-grid');
    clear(grid);
    const dockIds = new Set(['phone', 'messages', 'bank', 'settings']);
    apps.forEach(a => {
      if (dockIds.has(a.id)) return;
      const btn = h('button', {
        class: 'app-icon',
        data: { app: a.id },
        style: `background:${(a.color || '#555').replace(/[^#0-9a-zA-Z(), .]/g, '')}`,
        text: a.icon || '·',
      });
      const label = h('span', { class: 'app-label', text: a.label || a.id });
      grid.appendChild(h('div', { class: 'app-item' }, btn, label));
    });
  }

  function renderCallLog() {
    const el = document.getElementById('calllog-list');
    clear(el);
    if (!state.callLog.length) {
      el.appendChild(h('div', { class: 'list-row', text: 'Aucun appel' }));
      return;
    }
    state.callLog.slice(0, 20).forEach(c => {
      const type = c.type === 'in' ? '↙' : c.type === 'out' ? '↗' : '⚠';
      const row = h('div', { class: 'list-row', on: { click: () => post('call', { number: c.number }) } },
        h('span', { text: `${type} ${c.number}` }),
        h('span', { class: 'meta', text: fmtTime(c.ts) }),
      );
      el.appendChild(row);
    });
  }

  function renderConvos() {
    const list = document.getElementById('convo-list');
    clear(list);
    if (!state.conversations.length) {
      list.appendChild(h('div', { class: 'list-row', text: 'Aucun message' }));
      return;
    }
    state.conversations.forEach(c => {
      const last = c.messages[c.messages.length - 1];
      const row = h('div', { class: 'list-row', on: { click: () => openConvo(c.number, c.name) } },
        h('span', null,
          h('strong', { text: c.name || c.number }),
          h('div', { style: 'font-size:12px;color:#888', text: last ? last.text.slice(0, 40) : '' }),
        ),
        h('span', { class: 'meta', text: last ? fmtTime(last.ts) : '' }),
      );
      list.appendChild(row);
    });
  }

  function openConvo(number, name) {
    currentConvo = number;
    document.getElementById('convo-peer').textContent = name || number;
    document.getElementById('convo-list').classList.add('hidden');
    document.getElementById('convo-view').classList.remove('hidden');
    renderMessages();
  }
  function closeConvo() {
    currentConvo = null;
    document.getElementById('convo-view').classList.add('hidden');
    document.getElementById('convo-list').classList.remove('hidden');
  }
  function renderMessages() {
    const convo = (state.conversations || []).find(c => c.number === currentConvo);
    const el = document.getElementById('convo-messages');
    clear(el);
    if (!convo) return;
    convo.messages.forEach(m => {
      const b = h('div', {
        class: 'msg-bubble ' + (m.from === state.number ? 'me' : 'them'),
        text: m.text,
      });
      el.appendChild(b);
    });
    el.scrollTop = el.scrollHeight;
  }

  function renderContacts() {
    const el = document.getElementById('contact-list');
    clear(el);
    if (!state.contacts.length) {
      el.appendChild(h('div', { class: 'list-row', text: 'Aucun contact' }));
      return;
    }
    state.contacts.forEach(c => {
      const row = h('div', {
        class: 'list-row',
        on: {
          click: () => post('call', { number: c.number }),
          contextmenu: (e) => {
            e.preventDefault();
            if (confirm(`Supprimer ${c.name} ?`)) post('removeContact', { number: c.number });
          },
        },
      },
        h('span', null,
          document.createTextNode(c.name || ''),
          h('div', { style: 'font-size:12px;color:#888', text: c.number || '' }),
        ),
        h('span', { text: '📞' }),
      );
      el.appendChild(row);
    });
  }

  function renderBank() {
    document.getElementById('card-number').textContent = fmtCardNumber(state.number);
    document.getElementById('card-holder').textContent = state.number || 'TITULAIRE';
    document.getElementById('wallet-num').textContent = fmtCardNumber(state.number);
    document.getElementById('wallet-holder').textContent = state.number || 'TITULAIRE';
    document.getElementById('balance').textContent = fmtEur(state.bank.balance);
    const tx = document.getElementById('tx-list');
    clear(tx);
    const txs = state.bank.transactions || [];
    if (!txs.length) {
      tx.appendChild(h('div', { class: 'list-row', text: 'Aucune transaction' }));
      return;
    }
    txs.slice(0, 10).forEach(t => {
      const sign = (t.amount >= 0 ? '+' : '') + fmtEur(t.amount);
      const color = t.amount >= 0 ? '#2ecc71' : '#e74c3c';
      tx.appendChild(h('div', { class: 'list-row' },
        h('span', { text: t.label || t.type || '' }),
        h('span', { class: 'meta', style: `color:${color};font-weight:600`, text: sign }),
      ));
    });
  }

  function renderSettings() {
    document.getElementById('my-number').textContent = state.number || '—';
    document.getElementById('os-select').value = state.os || 'iphone';
  }

  function applyOS() {
    phoneEl.classList.toggle('android', state.os === 'android');
  }

  function renderAll() {
    applyOS();
    renderHome();
    renderCallLog();
    renderConvos();
    renderContacts();
    renderBank();
    renderSettings();
    renderMessages();
  }

  // ------ app routing ------
  document.body.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-app]');
    if (btn) {
      const id = btn.getAttribute('data-app');
      showView('view-' + id);
    }
    if (e.target.classList.contains('back')) { showView('view-home'); closeConvo(); }
    if (e.target.classList.contains('back-convo')) { closeConvo(); }
  });

  // ------ dialer ------
  document.querySelectorAll('.key').forEach(k => {
    k.addEventListener('click', () => {
      dialerBuffer += k.dataset.k;
      document.getElementById('dialer-display').textContent = dialerBuffer;
    });
  });
  document.getElementById('backspace').addEventListener('click', () => {
    dialerBuffer = dialerBuffer.slice(0, -1);
    document.getElementById('dialer-display').textContent = dialerBuffer;
  });
  document.getElementById('call-btn').addEventListener('click', () => {
    if (!dialerBuffer) return;
    post('call', { number: dialerBuffer });
  });

  // ------ tabs ------
  document.querySelectorAll('.tab').forEach(t => {
    t.addEventListener('click', () => {
      document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(x => x.classList.remove('active'));
      t.classList.add('active');
      document.getElementById('tab-' + t.dataset.tab).classList.add('active');
    });
  });

  // ------ messages ------
  document.getElementById('send-message').addEventListener('click', () => {
    const input = document.getElementById('message-input');
    const text = input.value.trim();
    if (!text || !currentConvo) return;
    post('sendMessage', { to: currentConvo, text });
    input.value = '';
  });
  document.getElementById('message-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') document.getElementById('send-message').click();
  });
  document.getElementById('new-message').addEventListener('click', () => {
    const number = prompt('Numéro du destinataire ?');
    if (!number) return;
    openConvo(number, number);
  });

  // ------ contacts ------
  document.getElementById('add-contact').addEventListener('click', () => {
    const name = prompt('Nom ?');
    if (!name) return;
    const number = prompt('Numéro ?');
    if (!number) return;
    post('addContact', { name, number });
  });

  // ------ settings ------
  document.getElementById('os-select').addEventListener('change', (e) => {
    state.os = e.target.value;
    applyOS();
    post('setOS', { os: e.target.value });
  });

  // ------ bank actions ------
  document.querySelectorAll('.bank-actions button').forEach(b => {
    b.addEventListener('click', () => {
      const action = b.dataset.action;
      if (action === 'deposit' || action === 'withdraw') {
        const amount = parseFloat(prompt(action === 'deposit' ? 'Montant à déposer ?' : 'Montant à retirer ?'));
        if (!amount || amount <= 0) return;
        post('bank', { type: action, amount });
      } else if (action === 'transfer') {
        const to = prompt('Numéro de téléphone du destinataire ?');
        if (!to) return;
        const amount = parseFloat(prompt('Montant ?'));
        if (!amount || amount <= 0) return;
        post('bank', { type: 'transfer', to, amount });
      }
    });
  });

  // ------ close (ESC) ------
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      root.classList.add('hidden');
      post('close');
    }
  });

  // ------ call overlay ------
  let callContext = null;  // { dir: 'in'|'out', number, name, state }
  function showIncomingCall(number, name) {
    callContext = { dir: 'in', number, name, state: 'ringing' };
    document.getElementById('call-name').textContent = name || number;
    document.getElementById('call-number').textContent = number;
    document.getElementById('call-status').textContent = 'Appel entrant…';
    document.getElementById('btn-answer').classList.remove('hidden');
    document.getElementById('btn-decline').classList.remove('hidden');
    document.getElementById('btn-hangup').classList.add('hidden');
    showView('view-call');
    root.classList.remove('hidden');
  }
  function showOutgoingCall(number, name) {
    callContext = { dir: 'out', number, name, state: 'ringing' };
    document.getElementById('call-name').textContent = name || number;
    document.getElementById('call-number').textContent = number;
    document.getElementById('call-status').textContent = 'Appel en cours…';
    document.getElementById('btn-answer').classList.add('hidden');
    document.getElementById('btn-decline').classList.add('hidden');
    document.getElementById('btn-hangup').classList.remove('hidden');
    showView('view-call');
  }
  function setCallConnected(number, name) {
    if (!callContext) callContext = { dir: 'in', number, name, state: 'active' };
    callContext.state = 'active';
    callContext.number = number;
    document.getElementById('call-name').textContent = name || number;
    document.getElementById('call-status').textContent = '● En communication';
    document.getElementById('btn-answer').classList.add('hidden');
    document.getElementById('btn-decline').classList.add('hidden');
    document.getElementById('btn-hangup').classList.remove('hidden');
  }
  function endCallUI(reason) {
    callContext = null;
    showToast('Appel terminé' + (reason ? ` (${reason})` : ''));
    showView('view-home');
  }

  document.getElementById('btn-answer').addEventListener('click', () => post('answer'));
  document.getElementById('btn-decline').addEventListener('click', () => post('decline'));
  document.getElementById('btn-hangup').addEventListener('click', () => post('hangup'));

  // ------ NUI message handler ------
  window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open') {
      apps = d.apps || apps;
      state = Object.assign(state, d.data || {});
      renderAll();
      showView('view-home');
      root.classList.remove('hidden');
    } else if (d.action === 'update') {
      state = Object.assign(state, d.data || {});
      renderAll();
    } else if (d.action === 'close') {
      root.classList.add('hidden');
    } else if (d.action === 'incomingCall') {
      showIncomingCall(d.from, d.name);
    } else if (d.action === 'outgoingCall') {
      showOutgoingCall(d.number, d.name);
    } else if (d.action === 'callConnected') {
      setCallConnected(d.number, d.name);
    } else if (d.action === 'callEnded') {
      endCallUI(d.reason);
    } else if (d.action === 'notify') {
      showToast(d.message, d.type);
    } else if (d.action === 'newMessage') {
      showToast(`SMS de ${d.from}: ${d.text}`);
    }
  });
})();
