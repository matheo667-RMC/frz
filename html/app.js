(function () {
    const banner = document.getElementById('banner');
    const titleEl = document.getElementById('banner-title');
    const subtitleEl = document.getElementById('banner-subtitle');
    const audio = document.getElementById('welcome-audio');

    function show(title, subtitle, playAudio) {
        if (title) titleEl.textContent = title;
        if (subtitle) subtitleEl.textContent = subtitle;
        banner.classList.remove('hidden');
        // Force reflow to re-trigger the transition when re-shown quickly.
        void banner.offsetWidth;
        banner.classList.add('visible');

        if (playAudio && audio) {
            try {
                audio.currentTime = 0;
                audio.volume = 0.9;
                const p = audio.play();
                if (p && typeof p.catch === 'function') {
                    p.catch(function () { /* autoplay blocked, ignore */ });
                }
            } catch (e) {
                /* ignore */
            }
        }
    }

    function hide() {
        banner.classList.remove('visible');
        banner.classList.add('hidden');
        if (audio) {
            try { audio.pause(); } catch (e) { /* ignore */ }
        }
    }

    window.addEventListener('message', function (event) {
        const data = event.data || {};
        if (data.action === 'show') {
            show(data.title, data.subtitle, data.playAudio);
        } else if (data.action === 'hide') {
            hide();
        }
    });
})();
