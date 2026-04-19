// FRZ Inventaire - NUI (drag & drop, context menu, weight)
(() => {
  const resourceName = (window.GetParentResourceName && GetParentResourceName()) || 'frz-inventory';

  const root = document.getElementById('root');
  const grid = document.getElementById('grid');
  const clothingLeft = document.getElementById('clothing-left');
  const clothingRight = document.getElementById('clothing-right');
  const dropZone = document.getElementById('drop-zone');
  const weightFill = document.getElementById('weight-fill');
  const weightLabel = document.getElementById('weight-label');
  const notify = document.getElementById('notify');
  const closeBtn = document.getElementById('close');

  let state = {
    grid: {},
    clothing: {},
    rows: 6,
    cols: 5,
    clothingSlots: [],
    items: {},
    maxWeight: 40,
  };

  function post(endpoint, body) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    }).catch(() => {});
  }

  // Safe DOM helpers : pas d'innerHTML avec des donnees utilisateur.
  function makeEl(tag, opts, ...children) {
    const el = document.createElement(tag);
    opts = opts || {};
    if (opts.class) el.className = opts.class;
    if (opts.text !== undefined) el.textContent = opts.text;
    if (opts.style) el.setAttribute('style', opts.style);
    for (const c of children) if (c != null) el.appendChild(c);
    return el;
  }
  function clear(el) { while (el.firstChild) el.removeChild(el.firstChild); }

  function close() {
    root.classList.add('hidden');
    post('close');
  }

  closeBtn.addEventListener('click', close);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') close();
  });

  // -------- Rendering --------
  function totalWeight() {
    let w = 0;
    for (const k of Object.keys(state.grid)) {
      const it = state.grid[k]; if (!it) continue;
      const meta = state.items[it.name];
      if (meta) w += (meta.weight || 0) * (it.count || 1);
    }
    return w;
  }

  function renderGrid() {
    grid.style.setProperty('--cols', state.cols || 5);
    clear(grid);
    const total = (state.rows || 6) * (state.cols || 5);
    for (let i = 1; i <= total; i++) {
      const slot = document.createElement('div');
      slot.className = 'slot empty';
      slot.dataset.slot = i;
      slot.draggable = false;

      const item = state.grid[i] || state.grid[String(i)];
      if (item) {
        const meta = state.items[item.name] || {};
        slot.classList.remove('empty');
        slot.draggable = true;
        slot.dataset.itemName = item.name;
        slot.appendChild(makeEl('div', { class: 'icon', text: meta.icon || '📦' }));
        slot.appendChild(makeEl('div', { class: 'name', text: meta.label || item.name }));
        if (item.count > 1) {
          slot.appendChild(makeEl('span', { class: 'count', text: String(item.count) }));
        }
        slot.title = (meta.description || meta.label || item.name);
      }

      wireSlotEvents(slot);
      grid.appendChild(slot);
    }
  }

  function renderClothing() {
    clear(clothingLeft);
    clear(clothingRight);
    const slots = state.clothingSlots || [];
    slots.forEach((s, idx) => {
      const el = document.createElement('div');
      el.className = 'cloth-slot';
      el.dataset.clothKey = s.key;
      const equipped = state.clothing[s.key];
      if (equipped) {
        el.classList.add('filled');
        const meta = state.items[equipped.name] || {};
        el.appendChild(makeEl('div', { class: 'cloth-label', text: s.label }));
        el.appendChild(makeEl('div', { class: 'cloth-item', text: meta.icon || '👕' }));
        el.appendChild(makeEl('div', { class: 'cloth-name', text: meta.label || equipped.name }));
      } else {
        el.appendChild(makeEl('div', { class: 'cloth-label', text: s.label }));
        el.appendChild(makeEl('div', { class: 'cloth-item', text: '·' }));
        el.appendChild(makeEl('div', { class: 'cloth-name', style: 'color:#5a6070', text: 'vide' }));
      }
      wireClothingEvents(el);
      (idx % 2 === 0 ? clothingLeft : clothingRight).appendChild(el);
    });
  }

  function renderWeight() {
    const w = totalWeight();
    const max = state.maxWeight || 40;
    const pct = max > 0 ? Math.min(100, (w / max) * 100) : 0;
    weightFill.style.width = `${pct}%`;
    weightLabel.textContent = `${w.toFixed(1)} / ${max.toFixed(1)} kg`;
  }

  function renderAll() {
    renderGrid();
    renderClothing();
    renderWeight();
  }

  // -------- Drag & drop --------
  let dragFrom = null;

  function wireSlotEvents(el) {
    el.addEventListener('dragstart', (e) => {
      if (el.classList.contains('empty')) { e.preventDefault(); return; }
      dragFrom = { type: 'grid', slot: parseInt(el.dataset.slot, 10), itemName: el.dataset.itemName };
      el.classList.add('dragging');
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', el.dataset.slot);
    });
    el.addEventListener('dragend', () => el.classList.remove('dragging'));
    el.addEventListener('dragover', (e) => { e.preventDefault(); el.classList.add('drag-over'); });
    el.addEventListener('dragleave', () => el.classList.remove('drag-over'));
    el.addEventListener('drop', (e) => {
      e.preventDefault();
      el.classList.remove('drag-over');
      if (!dragFrom) return;
      const to = parseInt(el.dataset.slot, 10);
      if (dragFrom.type === 'grid' && dragFrom.slot !== to) {
        post('move', { from: dragFrom.slot, to });
      } else if (dragFrom.type === 'clothing') {
        post('unequip', { slotKey: dragFrom.slotKey });
      }
      dragFrom = null;
    });
    el.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      if (el.classList.contains('empty')) return;
      const slotIdx = parseInt(el.dataset.slot, 10);
      showContextMenu(e.clientX, e.clientY, slotIdx, el.dataset.itemName);
    });
  }

  function wireClothingEvents(el) {
    const key = el.dataset.clothKey;
    el.addEventListener('dragover', (e) => { e.preventDefault(); el.classList.add('drag-over'); });
    el.addEventListener('dragleave', () => el.classList.remove('drag-over'));
    el.addEventListener('drop', (e) => {
      e.preventDefault();
      el.classList.remove('drag-over');
      if (dragFrom && dragFrom.type === 'grid') {
        post('equip', { from: dragFrom.slot, slotKey: key });
      }
      dragFrom = null;
    });
    el.addEventListener('dragstart', (e) => {
      if (!el.classList.contains('filled')) { e.preventDefault(); return; }
      dragFrom = { type: 'clothing', slotKey: key };
      e.dataTransfer.effectAllowed = 'move';
    });
    el.draggable = el.classList.contains('filled');
    el.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      if (!el.classList.contains('filled')) return;
      const x = e.clientX, y = e.clientY;
      showContextMenuClothing(x, y, key);
    });
    el.addEventListener('dblclick', () => {
      if (el.classList.contains('filled')) post('unequip', { slotKey: key });
    });
  }

  dropZone.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.classList.add('drag-over'); });
  dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
  dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropZone.classList.remove('drag-over');
    if (dragFrom && dragFrom.type === 'grid') {
      post('drop', { from: dragFrom.slot });
    }
    dragFrom = null;
  });

  // -------- Context menu --------
  let ctxMenu = null;
  function closeCtx() {
    if (ctxMenu) { ctxMenu.remove(); ctxMenu = null; }
  }
  function showContextMenu(x, y, slotIdx, itemName) {
    closeCtx();
    const meta = state.items[itemName] || {};
    const menu = document.createElement('div');
    menu.className = 'ctx-menu';
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    const btns = [];
    if (meta.usable) btns.push({ label: `Utiliser — ${meta.label || itemName}`, fn: () => post('use', { from: slotIdx }) });
    btns.push({ label: 'Jeter au sol', fn: () => post('drop', { from: slotIdx }), cls: 'danger' });
    btns.push({ label: 'Fermer', fn: () => {} });
    btns.forEach(b => {
      const btn = document.createElement('button');
      btn.textContent = b.label;
      if (b.cls) btn.className = b.cls;
      btn.addEventListener('click', () => { b.fn(); closeCtx(); });
      menu.appendChild(btn);
    });
    document.body.appendChild(menu);
    ctxMenu = menu;
  }
  function showContextMenuClothing(x, y, key) {
    closeCtx();
    const menu = document.createElement('div');
    menu.className = 'ctx-menu';
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    const btn = document.createElement('button');
    btn.textContent = 'Retirer le vêtement';
    btn.addEventListener('click', () => { post('unequip', { slotKey: key }); closeCtx(); });
    menu.appendChild(btn);
    document.body.appendChild(menu);
    ctxMenu = menu;
  }
  document.addEventListener('click', (e) => {
    if (ctxMenu && !ctxMenu.contains(e.target)) closeCtx();
  });

  // -------- Notifications --------
  let notifyTimer = null;
  function showNotify(msg, type) {
    notify.textContent = msg;
    notify.className = `notify ${type || ''}`;
    notify.classList.remove('hidden');
    if (notifyTimer) clearTimeout(notifyTimer);
    notifyTimer = setTimeout(() => notify.classList.add('hidden'), 2500);
  }

  // -------- NUI message handler --------
  window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open') {
      state = Object.assign(state, d);
      renderAll();
      root.classList.remove('hidden');
    } else if (d.action === 'update') {
      state.grid = d.grid || {};
      state.clothing = d.clothing || {};
      renderAll();
    } else if (d.action === 'close') {
      root.classList.add('hidden');
      closeCtx();
    } else if (d.action === 'notify') {
      showNotify(d.message, d.type);
    }
  });
})();
