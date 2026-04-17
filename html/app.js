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
    const rentalList = document.getElementById('rental-list');
    const rentalBalance = document.getElementById('rental-balance');
    const rentalError = document.getElementById('rental-error');
    const rentalCloseBtn = document.getElementById('rental-close');

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
        if (rentalBalance) rentalBalance.textContent = String(v || 0);
    }

    function renderRentalVehicles(vehicles, balance) {
        rentalList.innerHTML = '';
        (vehicles || []).forEach(function (v) {
            const row = document.createElement('div');
            row.className = 'rental-item';

            const info = document.createElement('div');
            info.className = 'rental-item-info';

            const label = document.createElement('div');
            label.className = 'rental-item-label';
            label.textContent = v.label || v.model;

            const sub = document.createElement('div');
            sub.className = 'rental-item-sub';
            sub.textContent = String(v.model || '').toUpperCase();

            info.appendChild(label);
            info.appendChild(sub);

            const price = document.createElement('div');
            const priceVal = Number(v.price || 0);
            price.className = 'rental-item-price' + (priceVal === 0 ? ' free' : '');
            price.textContent = priceVal === 0 ? 'GRATUIT' : ('$ ' + priceVal);

            const btn = document.createElement('button');
            btn.className = 'rental-item-btn';
            btn.type = 'button';
            btn.textContent = priceVal === 0 ? 'Prendre' : 'Louer';
            if (priceVal > 0 && Number(balance || 0) < priceVal) {
                btn.disabled = true;
                btn.classList.add('disabled');
                btn.textContent = 'Fonds insuffisants';
            }
            btn.addEventListener('click', function () {
                sendNui('rent', { model: v.model });
            });

            row.appendChild(info);
            row.appendChild(price);
            row.appendChild(btn);
            rentalList.appendChild(row);
        });
    }

    function showRental(balance, vehicles) {
        setBalance(balance);
        renderRentalVehicles(vehicles, balance);
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
                showRental(data.balance, data.vehicles);
                break;
            case 'hideRental':
                hideRental();
                break;
            case 'rentalError':
                showRentalError(data.message, data.balance);
                break;
            case 'rentalUpdateBalance':
                setBalance(data.balance);
                break;
        }
    });
})();
