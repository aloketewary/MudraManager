// ── Mudra Manager Theme Toggle ──
// Init: check localStorage, then system preference, default to dark
if (localStorage.getItem('theme') === 'light') {
    document.documentElement.classList.remove('dark');
} else if (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: light)').matches) {
    document.documentElement.classList.remove('dark');
}

function toggleMudraTheme() {
    document.documentElement.classList.toggle('dark');
    localStorage.setItem('theme', document.documentElement.classList.contains('dark') ? 'dark' : 'light');
}

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-theme-toggle]').forEach(btn => {
        btn.addEventListener('click', toggleMudraTheme);
    });
});
