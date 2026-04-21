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
        }
    });
})();
