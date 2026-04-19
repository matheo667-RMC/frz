(function () {
    const banner = document.getElementById('banner');
    const titleEl = document.getElementById('banner-title');
    const subtitleEl = document.getElementById('banner-subtitle');
    const welcomeAudio = document.getElementById('welcome-audio');

    const titleCard = document.getElementById('title-card');
    const titleCardMain = document.getElementById('title-card-main');
    const titleCardSub = document.getElementById('title-card-sub');

    const planeAudio = document.getElementById('plane-audio');

    function showBanner(title, subtitle, playAudio) {
        if (title) titleEl.textContent = title;
        if (subtitle) subtitleEl.textContent = subtitle;
        banner.classList.remove('hidden');
        void banner.offsetWidth;
        banner.classList.add('visible');

        if (playAudio && welcomeAudio) {
            try {
                welcomeAudio.currentTime = 0;
                welcomeAudio.volume = 0.95;
                const p = welcomeAudio.play();
                if (p && typeof p.catch === 'function') {
                    p.catch(function () { /* autoplay blocked, ignore */ });
                }
            } catch (e) { /* ignore */ }
        }
    }

    function hideBanner() {
        banner.classList.remove('visible');
        banner.classList.add('hidden');
        if (welcomeAudio) {
            try { welcomeAudio.pause(); } catch (e) { /* ignore */ }
        }
    }

    function showTitleCard(main, sub) {
        if (main) titleCardMain.textContent = main;
        if (sub) titleCardSub.textContent = sub;
        titleCard.classList.remove('hidden');
        void titleCard.offsetWidth;
        titleCard.classList.add('visible');
    }

    function hideTitleCard() {
        titleCard.classList.remove('visible');
        titleCard.classList.add('hidden');
    }

    function playPlaneLanding() {
        if (!planeAudio) return;
        try {
            planeAudio.currentTime = 0;
            planeAudio.volume = 0.85;
            const p = planeAudio.play();
            if (p && typeof p.catch === 'function') {
                p.catch(function () { /* autoplay blocked, ignore */ });
            }
        } catch (e) { /* ignore */ }
    }

    function stopPlaneLanding() {
        if (!planeAudio) return;
        try { planeAudio.pause(); } catch (e) { /* ignore */ }
    }

    // ----- Rental menu (car dealer NPC) -----
    const rental = document.getElementById('rental');
    const rentalTabs = document.getElementById('rental-tabs');
    const rentalList = document.getElementById('rental-list');
    const rentalBalance = document.getElementById('rental-balance');
    const rentalError = document.getElementById('rental-error');
    const rentalCloseBtn = document.getElementById('rental-close');

    // Cache de la liste affichee pour pouvoir re-render les boutons quand le
    // solde change (admin `frzgivemoney` en live, erreur serveur, etc.).
    let currentVehicles = [];
    let currentCategories = [];
    let currentBalance = 0;
    let currentCategory = null; // cle de la categorie active (ex: 'bike')

    // Mapping visuel pour les couleurs des vehicules (pastille affichee dans
    // la fiche du vehicule). Les cles doivent matcher Config.CarRental.colors
    // cote Lua.
    const COLOR_SWATCH = {
        black: '#111111',
        white: '#f2f2ef',
        red:   '#c92a2a',
    };

    const CATEGORY_ICON = {
        bike: 'B',
        moto: 'M',
        car:  'V',
    };

    function sendNui(name, payload) {
        try {
            fetch('https://' + (window.GetParentResourceName ? GetParentResourceName() : 'frz-rp-spawn') + '/' + name, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(payload || {}),
            }).catch(function () { /* ignore */ });
        } catch (e) { /* ignore */ }
    }

    function setBalance(v) {
        currentBalance = Number(v) || 0;
        if (rentalBalance) rentalBalance.textContent = String(currentBalance);
    }

    function refreshRentalButtons() {
        // Re-render la liste avec l'etat actuel (solde) pour que les boutons
        // "Fonds insuffisants" passent en "Louer" (ou l'inverse) apres un
        // changement de solde en live.
        renderRentalVehicles();
    }

    function vehiclesForCurrentCategory() {
        if (!currentCategory) return currentVehicles;
        return currentVehicles.filter(function (v) {
            return v.category === currentCategory;
        });
    }

    function renderRentalTabs() {
        rentalTabs.innerHTML = '';
        (currentCategories || []).forEach(function (c) {
            if (!c || !c.key) return;
            const btn = document.createElement('button');
            btn.className = 'rental-tab';
            btn.type = 'button';
            btn.dataset.category = c.key;

            const icon = document.createElement('span');
            icon.className = 'rental-tab-icon';
            icon.textContent = CATEGORY_ICON[c.key] || '?';

            const label = document.createElement('span');
            label.className = 'rental-tab-label';
            label.textContent = c.label || c.key;

            const count = currentVehicles.filter(function (v) {
                return v.category === c.key;
            }).length;
            const badge = document.createElement('span');
            badge.className = 'rental-tab-count';
            badge.textContent = String(count);

            btn.appendChild(icon);
            btn.appendChild(label);
            btn.appendChild(badge);
            if (c.key === currentCategory) btn.classList.add('active');
            btn.addEventListener('click', function () {
                if (currentCategory !== c.key) {
                    currentCategory = c.key;
                    renderRentalTabs();
                    renderRentalVehicles();
                }
            });
            rentalTabs.appendChild(btn);
        });
    }

    function formatPrice(price) {
        return price === 0 ? 'GRATUIT' : ('$ ' + price);
    }

    function renderRentalVehicles() {
        rentalList.innerHTML = '';
        const list = vehiclesForCurrentCategory();
        if (list.length === 0) {
            const empty = document.createElement('div');
            empty.className = 'rental-empty';
            empty.textContent = 'Aucun vehicule dans cette categorie.';
            rentalList.appendChild(empty);
            return;
        }
        list.forEach(function (v) {
            const card = document.createElement('div');
            card.className = 'rental-card';

            // Preview (pastille de couleur + icone categorie)
            const preview = document.createElement('div');
            preview.className = 'rental-card-preview';
            const swatch = COLOR_SWATCH[v.color] || '#444';
            preview.style.background = 'linear-gradient(135deg, ' + swatch + ' 0%, rgba(0,0,0,0.6) 100%)';
            const previewIcon = document.createElement('div');
            previewIcon.className = 'rental-card-preview-icon';
            previewIcon.textContent = CATEGORY_ICON[v.category] || '?';
            preview.appendChild(previewIcon);

            // Info principale
            const info = document.createElement('div');
            info.className = 'rental-card-info';

            const label = document.createElement('div');
            label.className = 'rental-card-label';
            label.textContent = v.label || v.model;

            const meta = document.createElement('div');
            meta.className = 'rental-card-meta';
            const colorLabel = (v.color || 'standard').toUpperCase();
            meta.innerHTML = '<span>' + String(v.model || '').toUpperCase() + '</span>'
                + '<span class="rental-card-dot">&middot;</span>'
                + '<span>' + colorLabel + '</span>';

            info.appendChild(label);
            info.appendChild(meta);

            // Prix
            const priceVal = Number(v.price || 0);
            const price = document.createElement('div');
            price.className = 'rental-card-price' + (priceVal === 0 ? ' free' : '');
            price.textContent = formatPrice(priceVal);

            // Bouton
            const btn = document.createElement('button');
            btn.className = 'rental-card-btn';
            btn.type = 'button';
            btn.textContent = priceVal === 0 ? 'Prendre' : 'Louer';
            if (priceVal > 0 && currentBalance < priceVal) {
                btn.disabled = true;
                btn.classList.add('disabled');
                btn.textContent = 'Fonds insuffisants';
            }
            btn.addEventListener('click', function () {
                if (btn.disabled) return;
                sendNui('rent', { model: v.model });
            });

            card.appendChild(preview);
            card.appendChild(info);
            card.appendChild(price);
            card.appendChild(btn);
            rentalList.appendChild(card);
        });
    }

    function pickDefaultCategory() {
        if (!currentCategories || currentCategories.length === 0) return null;
        // Choisit la premiere categorie qui a au moins un vehicule, sinon la
        // premiere tout court.
        for (let i = 0; i < currentCategories.length; i++) {
            const key = currentCategories[i].key;
            if (currentVehicles.some(function (v) { return v.category === key; })) {
                return key;
            }
        }
        return currentCategories[0].key;
    }

    function showRental(balance, vehicles, categories) {
        currentVehicles = Array.isArray(vehicles) ? vehicles.slice() : [];
        currentCategories = Array.isArray(categories) ? categories.slice() : [];
        currentCategory = pickDefaultCategory();
        setBalance(balance);
        renderRentalTabs();
        renderRentalVehicles();
        if (rentalError) {
            rentalError.textContent = '';
            rentalError.classList.add('hidden');
        }
        rental.classList.remove('hidden');
        void rental.offsetWidth;
        rental.classList.add('visible');
    }

    function hideRental() {
        rental.classList.remove('visible');
        rental.classList.add('hidden');
        if (rentalError) {
            rentalError.textContent = '';
            rentalError.classList.add('hidden');
        }
    }

    function showRentalError(message, balance) {
        if (typeof balance === 'number') {
            setBalance(balance);
        }
        if (!rentalError) return;
        rentalError.textContent = message || '';
        rentalError.classList.remove('hidden');
    }

    if (rentalCloseBtn) {
        rentalCloseBtn.addEventListener('click', function () {
            sendNui('close', {});
        });
    }

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && rental && rental.classList.contains('visible')) {
            sendNui('close', {});
        }
    });

    window.addEventListener('message', function (event) {
        const data = event.data || {};
        switch (data.action) {
            case 'show':
                showBanner(data.title, data.subtitle, data.playAudio);
                break;
            case 'hide':
                hideBanner();
                break;
            case 'showTitle':
                showTitleCard(data.title, data.subtitle);
                break;
            case 'hideTitle':
                hideTitleCard();
                break;
            case 'planeLanding':
                playPlaneLanding();
                break;
            case 'stopPlaneLanding':
                stopPlaneLanding();
                break;
            case 'showRental':
                showRental(data.balance, data.vehicles, data.categories);
                break;
            case 'hideRental':
                hideRental();
                break;
            case 'rentalError':
                showRentalError(data.message, data.balance);
                refreshRentalButtons();
                break;
            case 'rentalUpdateBalance':
                setBalance(data.balance);
                refreshRentalButtons();
                break;
        }
    });
})();
