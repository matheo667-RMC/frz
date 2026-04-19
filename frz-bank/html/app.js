// FRZ Bank NUI
(() => {
  const resourceName = (window.GetParentResourceName && GetParentResourceName()) || 'frz-bank';
  const root = document.getElementById('root');
  const toast = document.getElementById('toast');

  let account = { balance: 0, transactions: [], card: { holder: '—' } };
  let context = 'atm';
  let maxWithdraw = 10000;
  let maxTransfer = 50000;

  let amountMode = null;  // 'deposit' | 'withdraw'
  let amountBuffer = '';

  function post(endpoint, body) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    }).catch(() => {});
  }
  function fmt(n) {
    return (Number(n) || 0).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' €';
  }
  function fmtTime(ts) {
    const d = new Date((ts || 0) * 1000);
    return d.toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
  }
  function showToast(msg, type) {
    toast.textContent = msg;
    toast.className = 'toast ' + (type || '');
    setTimeout(() => toast.classList.add('hidden'), 2500);
    toast.classList.remove('hidden');
  }
  function render() {
    document.getElementById('balance').textContent = fmt(account.balance);
    const holder = (account.card && account.card.holder) || '—';
    document.getElementById('card-holder').textContent = holder;
    const digits = (holder || '').replace(/\D/g, '').slice(-4).padStart(4, '•');
    document.getElementById('card-last').textContent = digits;
    const list = document.getElementById('tx-list');
    list.innerHTML = '';
    const tx = account.transactions || [];
    if (!tx.length) { list.innerHTML = '<div class="tx-row"><span class="tx-label">Aucune transaction</span></div>'; return; }
    tx.slice(0, 20).forEach(t => {
      const row = document.createElement('div');
      row.className = 'tx-row';
      const sign = t.amount >= 0 ? '+' : '';
      row.innerHTML = `
        <span>
          <div class="tx-label">${t.label || t.type}</div>
          <div class="tx-ts">${fmtTime(t.ts)}</div>
        </span>
        <span class="tx-amount ${t.amount >= 0 ? 'pos' : 'neg'}">${sign}${fmt(t.amount)}</span>
      `;
      list.appendChild(row);
    });
  }

  function setContextLabel() {
    const labels = { atm: 'Distributeur automatique', bank: 'Comptoir bancaire', phone: 'Téléphone' };
    document.getElementById('context-label').textContent = labels[context] || 'Banque';
  }

  // ----- Panes -----
  function showMenu() {
    document.getElementById('menu').classList.remove('hidden');
    document.querySelectorAll('.pane').forEach(p => p.classList.add('hidden'));
  }
  function showAmountPane(mode) {
    amountMode = mode;
    amountBuffer = '';
    document.getElementById('pane-title').textContent = mode === 'deposit' ? 'Montant à déposer' : 'Montant à retirer';
    document.getElementById('amount-display').textContent = '0 €';
    document.getElementById('menu').classList.add('hidden');
    document.querySelectorAll('.pane').forEach(p => p.classList.add('hidden'));
    document.getElementById('pane-amount').classList.remove('hidden');
  }
  function showTransferPane() {
    document.getElementById('transfer-to').value = '';
    document.getElementById('transfer-amount').value = '';
    document.getElementById('menu').classList.add('hidden');
    document.querySelectorAll('.pane').forEach(p => p.classList.add('hidden'));
    document.getElementById('pane-transfer').classList.remove('hidden');
  }

  // ----- Wiring -----
  document.getElementById('close').addEventListener('click', () => post('close'));
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') post('close');
  });

  document.querySelectorAll('.act').forEach(b => {
    b.addEventListener('click', () => {
      const a = b.dataset.act;
      if (a === 'deposit') {
        if (context === 'atm') { showToast('Les dépôts se font au comptoir de la banque.', 'error'); return; }
        showAmountPane('deposit');
      } else if (a === 'withdraw') {
        showAmountPane('withdraw');
      } else if (a === 'transfer') {
        if (context === 'atm') { showToast('Virements disponibles au comptoir ou sur votre téléphone.', 'error'); return; }
        showTransferPane();
      } else if (a === 'history') {
        // L'historique est deja affiche a gauche, on flash juste la zone.
        document.getElementById('tx-list').scrollTo({ top: 0, behavior: 'smooth' });
        showToast('Historique à gauche.');
      }
    });
  });

  document.querySelectorAll('.key').forEach(k => {
    k.addEventListener('click', () => {
      const v = k.dataset.k;
      if (v === 'clear') amountBuffer = '';
      else if (v === 'back') amountBuffer = amountBuffer.slice(0, -1);
      else amountBuffer = (amountBuffer + v).replace(/^0+/, '') || '0';
      document.getElementById('amount-display').textContent = fmt(parseInt(amountBuffer || '0', 10));
    });
  });
  document.querySelectorAll('.qk-row button').forEach(b => {
    b.addEventListener('click', () => {
      amountBuffer = String(b.dataset.qk);
      document.getElementById('amount-display').textContent = fmt(parseInt(amountBuffer, 10));
    });
  });

  document.getElementById('cancel-amount').addEventListener('click', showMenu);
  document.getElementById('confirm-amount').addEventListener('click', () => {
    const amount = parseInt(amountBuffer || '0', 10);
    if (!amount) { showToast('Montant invalide', 'error'); return; }
    if (amountMode === 'withdraw' && amount > maxWithdraw) {
      showToast(`Plafond de retrait : ${fmt(maxWithdraw)}`, 'error'); return;
    }
    post('action', { type: amountMode, amount });
    showMenu();
  });

  document.getElementById('cancel-transfer').addEventListener('click', showMenu);
  document.getElementById('confirm-transfer').addEventListener('click', () => {
    const to = document.getElementById('transfer-to').value.trim();
    const amount = parseInt(document.getElementById('transfer-amount').value, 10);
    if (!to || !amount || amount <= 0) { showToast('Champs invalides', 'error'); return; }
    if (amount > maxTransfer) { showToast(`Plafond : ${fmt(maxTransfer)}`, 'error'); return; }
    post('action', { type: 'transfer', to, amount });
    showMenu();
  });

  // ----- NUI messages -----
  window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open') {
      account = d.account || account;
      context = d.context || 'atm';
      maxWithdraw = d.maxWithdraw || maxWithdraw;
      maxTransfer = d.maxTransfer || maxTransfer;
      setContextLabel();
      render();
      showMenu();
      root.classList.remove('hidden');
    } else if (d.action === 'update') {
      account = d.account || account;
      render();
    } else if (d.action === 'close') {
      root.classList.add('hidden');
    } else if (d.action === 'notify') {
      showToast(d.message, d.type);
    }
  });
})();
