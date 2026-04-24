/* ═══ MUDRA MANAGER — 2026 INTERACTIONS ═══ */

// ── Theme ──
const html = document.documentElement;
if (localStorage.theme === 'light' || (!localStorage.theme && matchMedia('(prefers-color-scheme:light)').matches)) html.dataset.theme = 'light';
function toggleTheme() { html.dataset.theme = html.dataset.theme === 'dark' ? 'light' : 'dark'; localStorage.theme = html.dataset.theme; }
document.getElementById('theme-toggle')?.addEventListener('click', toggleTheme);
document.getElementById('theme-toggle-m')?.addEventListener('click', toggleTheme);

// ── Mobile menu ──
const mm = document.getElementById('mobile-menu'), mb = document.getElementById('menu-btn');
mb?.addEventListener('click', () => mm.classList.add('open'));
mm?.querySelectorAll('a, .mm-link').forEach(a => a.addEventListener('click', () => mm.classList.remove('open')));
document.addEventListener('keydown', e => { if (e.key === 'Escape') mm?.classList.remove('open'); });

// ── Carousel ──
const imgs = document.querySelectorAll('.phone-img');
let ci = 0;
if (imgs.length) setInterval(() => { imgs[ci].classList.remove('active'); ci = (ci + 1) % imgs.length; imgs[ci].classList.add('active'); }, 4000);

// ── Scroll reveal ──
const ro = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); ro.unobserve(e.target); } }), { threshold: 0.1, rootMargin: '0px 0px -60px 0px' });
document.querySelectorAll('.reveal-section').forEach(el => ro.observe(el));

// ── Parallax phone ──
const hp = document.getElementById('hero-phone');
if (hp) window.addEventListener('scroll', () => { if (scrollY < innerHeight) hp.style.transform = `translateY(${scrollY * 0.08}px)`; }, { passive: true });

// ── Stat counters ──
document.querySelectorAll('.stat-n').forEach(el => {
    const t = +el.dataset.target, s = el.dataset.suffix || '';
    let done = false;
    new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting && !done) { done = true; let c = 0; const step = Math.max(1, Math.ceil(t / 30)); const iv = setInterval(() => { c = Math.min(c + step, t); el.textContent = c + s; if (c >= t) clearInterval(iv); }, 30); } }), { threshold: 0.5 }).observe(el);
});

// ── Bento glow ──
document.querySelectorAll('.feat-card').forEach(c => {
    c.addEventListener('mousemove', e => { const r = c.getBoundingClientRect(); c.style.setProperty('--mx', (e.clientX - r.left) + 'px'); c.style.setProperty('--my', (e.clientY - r.top) + 'px'); });
});

// ── Preview tabs ──
const caps = ['AI insights, balances, and alerts at a glance', 'Bank SMS parsed and categorized automatically', 'Spending patterns, health score, trends', 'Category allocation, pace tracking, smart alerts'];
document.querySelectorAll('.ptab').forEach(tab => {
    tab.addEventListener('click', () => {
        const i = tab.dataset.i;
        document.querySelectorAll('.ptab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        document.querySelectorAll('.pdev-img').forEach(p => p.classList.remove('active'));
        document.querySelector(`.pdev-img[data-s="${i}"]`)?.classList.add('active');
        const cap = document.getElementById('pcap');
        if (cap) { cap.style.opacity = 0; setTimeout(() => { cap.textContent = caps[i]; cap.style.opacity = 1; }, 150); }
    });
});

// ── Floating CTA ──
const fc = document.getElementById('float-cta');
if (fc) window.addEventListener('scroll', () => fc.classList.toggle('show', scrollY > innerHeight * 0.7), { passive: true });
