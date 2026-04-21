// Dead Zone RP - Survival HUD - NUI side.
// Recoit des messages { type: 'init' | 'update' | 'visibility' } depuis Lua.

(function () {
    const hud = document.getElementById('hud');

    const fills = {
        hunger: document.getElementById('fill-hunger'),
        thirst: document.getElementById('fill-thirst'),
        fatigue: document.getElementById('fill-fatigue'),
        infection: document.getElementById('fill-infection'),
    };
    const values = {
        hunger: document.getElementById('val-hunger'),
        thirst: document.getElementById('val-thirst'),
        fatigue: document.getElementById('val-fatigue'),
        infection: document.getElementById('val-infection'),
    };

    const LOW_THRESHOLD = 25;

    function applyInit(data) {
        if (typeof data.positionX === 'number') hud.style.left = data.positionX + '%';
        if (typeof data.positionY === 'number') hud.style.top  = data.positionY + '%';
        if (typeof data.opacity   === 'number') hud.style.opacity = String(data.opacity);
        hud.classList.remove('hidden');
    }

    function applyUpdate(data) {
        hud.classList.remove('hidden');

        ['hunger', 'thirst', 'fatigue'].forEach((stat) => {
            const v = clamp(data[stat], 0, 100);
            fills[stat].style.width = v + '%';
            values[stat].textContent = v;
            fills[stat].parentElement.parentElement.classList.toggle('low', v <= LOW_THRESHOLD);
        });

        const inf = clamp(data.infection, 0, 100);
        fills.infection.style.width = inf + '%';
        values.infection.textContent = inf;
        const infBar = fills.infection.parentElement.parentElement;
        infBar.classList.toggle('active', inf > 0);
        infBar.classList.toggle('low', inf >= 50);
    }

    function applyVisibility(visible) {
        hud.classList.toggle('hidden', !visible);
    }

    function clamp(v, lo, hi) {
        v = Number(v) || 0;
        if (v < lo) return lo;
        if (v > hi) return hi;
        return Math.round(v);
    }

    window.addEventListener('message', (ev) => {
        const data = ev.data || {};
        switch (data.type) {
            case 'init':       return applyInit(data);
            case 'update':     return applyUpdate(data);
            case 'visibility': return applyVisibility(!!data.visible);
        }
    });
})();
