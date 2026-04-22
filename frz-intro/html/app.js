// Dead Zone RP - Intro NUI.

const root = document.getElementById('intro');
const titleEl = document.getElementById('title');
const subtitleEl = document.getElementById('subtitle');
const taglineEl = document.getElementById('tagline');

let hideTimer = null;

function play(data) {
    if (data.title)    titleEl.querySelector('.glitch').dataset.text = data.title;
    if (data.title)    titleEl.querySelector('.glitch').textContent = data.title;
    if (data.subtitle) subtitleEl.textContent = data.subtitle;
    if (data.tagline)  taglineEl.textContent = data.tagline;

    root.classList.remove('hidden');
    // Reset l'animation si rejouee.
    root.classList.remove('play');
    void root.offsetWidth; // reflow pour rejouer l'animation CSS.
    root.classList.add('play');

    if (hideTimer) clearTimeout(hideTimer);
    const duration = data.duration || 6500;
    hideTimer = setTimeout(() => {
        root.classList.add('hidden');
        root.classList.remove('play');
    }, duration + 200);
}

window.addEventListener('message', (e) => {
    const data = e.data || {};
    if (data.action === 'play') {
        play(data);
    } else if (data.action === 'stop') {
        if (hideTimer) clearTimeout(hideTimer);
        root.classList.add('hidden');
        root.classList.remove('play');
    }
});

// Mode preview standalone : ouvre index.html?preview=1 dans un navigateur
// pour voir l'anim hors FiveM. Inerte en prod (FiveM n'ajoute jamais ce param).
if (new URLSearchParams(location.search).get('preview') === '1') {
    document.body.style.background = '#000';
    play({
        title: 'DEAD ZONE',
        subtitle: 'Bienvenue dans la',
        tagline: 'Les morts sont sortis. Tiens bon.',
        duration: 6500,
    });
}
