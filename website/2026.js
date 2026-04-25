// MUDRA — LIQUID FINANCE

// Theme
const h = document.documentElement;
if (localStorage.theme === 'light' || (!localStorage.theme && matchMedia('(prefers-color-scheme:light)').matches)) h.dataset.theme = 'light';
function flip() {
    h.dataset.theme = h.dataset.theme === 'dark' ? 'light' : 'dark';
    localStorage.theme = h.dataset.theme;
    updateThemeIcon();
    updateTransparent();
}
function updateThemeIcon() {
    document.querySelectorAll('.theme-icon').forEach(i => {
        i.className = h.dataset.theme === 'dark' ? 'fas fa-sun theme-icon' : 'fas fa-moon theme-icon';
    });
}
document.getElementById('theme-toggle')?.addEventListener('click', flip);
updateThemeIcon();

// Mobile menu
const mob = document.getElementById('mob'), mb = document.getElementById('menu-btn');
function closeMob() { mob?.classList.remove('open'); }
mb?.addEventListener('click', () => mob?.classList.add('open'));
document.getElementById('mob-close')?.addEventListener('click', closeMob);
mob?.querySelectorAll('.ml').forEach(a => a.addEventListener('click', closeMob));
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeMob(); });

// Carousel with dots
const slides = document.querySelectorAll('#carousel img');
const dots = document.querySelectorAll('#hero-dots button');
let si = 0, autoplay;
function goSlide(i) {
    slides[si]?.classList.remove('on');
    dots[si]?.classList.remove('on');
    si = i;
    slides[si]?.classList.add('on');
    dots[si]?.classList.add('on');
}
function startAutoplay() { autoplay = setInterval(() => goSlide((si + 1) % slides.length), 4000); }
dots.forEach(d => d.addEventListener('click', () => {
    clearInterval(autoplay);
    goSlide(+d.dataset.ci);
    startAutoplay();
}));
if (slides.length) startAutoplay();

// Scroll reveal
const io = new IntersectionObserver(es => es.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
}), { threshold: 0.05, rootMargin: '0px 0px -40px 0px' });
document.querySelectorAll('.reveal').forEach(el => io.observe(el));

// Parallax
const phone = document.getElementById('hero-phone');
if (phone) window.addEventListener('scroll', () => {
    if (scrollY < innerHeight) phone.style.transform = `translateY(${scrollY * 0.06}px)`;
}, { passive: true });

// Tabbed features
const tabs = document.querySelectorAll('.ftab');
const panels = document.querySelectorAll('.fpanel');
const fImgs = document.querySelectorAll('[data-fp]');
let ftab = 0, ftabTimer;
function goTab(i) {
    tabs[ftab]?.classList.remove('on');
    panels[ftab]?.classList.remove('on');
    fImgs.forEach(img => img.classList.remove('on'));
    ftab = i;
    tabs[ftab]?.classList.add('on');
    panels[ftab]?.classList.add('on');
    const target = document.querySelector(`[data-fp="${ftab}"]`);
    if (target) target.classList.add('on');
}
function startFtab() { ftabTimer = setInterval(() => goTab((ftab + 1) % tabs.length), 6000); }
tabs.forEach(t => t.addEventListener('click', () => {
    clearInterval(ftabTimer);
    goTab(+t.dataset.tab);
    startFtab();
}));
if (tabs.length) startFtab();

// Theatrical Transparent App reveal
const transStage = document.getElementById('trans-stage');
if (transStage) {
    let transRevealed = false;
    const transIo = new IntersectionObserver(es => {
        if (es[0].isIntersecting && !transRevealed) {
            transRevealed = true;
            transIo.unobserve(transStage);
            const items = transStage.querySelectorAll('[data-reveal]');
            items.forEach(el => {
                const delay = (+el.dataset.reveal - 1) * 200;
                setTimeout(() => el.classList.add('show'), delay);
            });
            // Quote reveal after all items
            const quote = document.querySelector('.trans-quote[data-reveal]');
            if (quote) {
                const delay = (+quote.dataset.reveal - 1) * 200;
                setTimeout(() => quote.classList.add('show'), delay);
            }
        }
    }, { threshold: 0.2 });
    transIo.observe(transStage);
}

// Live Ledger — simulated SMS pipeline
const ledgerData = [
    { sender: 'HDFC Bank', body: 'Rs 450.00 debited from A/c XX4521 for SWIGGY on 15-Jun', icon: 'fa-utensils', merchant: 'Swiggy', cat: 'Food & Dining', amount: '-₹450' },
    { sender: 'SBI', body: 'Your A/c XX8832 credited with Rs 45,000.00 — NEFT from ACME Corp', icon: 'fa-building', merchant: 'ACME Corp', cat: 'Salary', amount: '+₹45,000' },
    { sender: 'ICICI Bank', body: 'Rs 1,299.00 debited for Amazon.in on Card XX7744', icon: 'fa-cart-shopping', merchant: 'Amazon', cat: 'Shopping', amount: '-₹1,299' },
    { sender: 'Paytm', body: 'Paid Rs 200.00 to Uber via UPI. Ref: 4829173650', icon: 'fa-car', merchant: 'Uber', cat: 'Transport', amount: '-₹200' },
    { sender: 'Kotak Bank', body: 'Rs 850.00 debited from A/c XX3391 for Netflix', icon: 'fa-tv', merchant: 'Netflix', cat: 'Entertainment', amount: '-₹850' },
];
const ledgerSection = document.getElementById('ledger');
if (ledgerSection) {
    let li = 0, ledgerRunning = false;
    const smsBubble = document.getElementById('sms-bubble');
    const smsSender = document.getElementById('sms-sender');
    const smsBody = document.getElementById('sms-body');
    const txnCard = document.getElementById('txn-card');
    const txnIcon = document.getElementById('txn-icon');
    const txnMerchant = document.getElementById('txn-merchant');
    const txnCat = document.getElementById('txn-cat');
    const txnAmount = document.getElementById('txn-amount');
    const ledgerArrow = document.querySelector('.ledger-arrow');
    const ledgerLock = document.getElementById('ledger-lock');

    function runLedger() {
        const d = ledgerData[li];
        // Reset
        smsBubble.classList.remove('show');
        txnCard.classList.remove('show');
        ledgerArrow.classList.remove('show');
        ledgerLock.classList.remove('show');

        setTimeout(() => {
            // Step 1: SMS arrives
            smsSender.textContent = d.sender;
            smsBody.textContent = d.body;
            smsBubble.classList.add('show');
        }, 200);

        setTimeout(() => {
            // Step 2: Arrow
            ledgerArrow.classList.add('show');
        }, 1000);

        setTimeout(() => {
            // Step 3: Transaction card
            txnIcon.innerHTML = `<i class="fas ${d.icon}"></i>`;
            txnMerchant.textContent = d.merchant;
            txnCat.textContent = d.cat;
            txnAmount.textContent = d.amount;
            txnAmount.style.color = d.amount.startsWith('+') ? 'var(--green)' : 'var(--red)';
            txnCard.classList.add('show');
        }, 1400);

        setTimeout(() => {
            // Step 4: Encrypted
            ledgerLock.classList.add('show');
        }, 2000);

        li = (li + 1) % ledgerData.length;
    }

    const ledgerIo = new IntersectionObserver(es => {
        if (es[0].isIntersecting && !ledgerRunning) {
            ledgerRunning = true;
            runLedger();
            setInterval(runLedger, 4000);
        }
    }, { threshold: 0.3 });
    ledgerIo.observe(ledgerSection);
}

// Floating CTA
const fc = document.getElementById('fcta');
const footer = document.querySelector('footer');
if (fc && footer) {
    const footIo = new IntersectionObserver(es => {
        es.forEach(e => fc.classList.toggle('hide', e.isIntersecting));
    }, { threshold: 0.1 });
    footIo.observe(footer);
    window.addEventListener('scroll', () => {
        fc.classList.toggle('on', scrollY > innerHeight * 0.6);
    }, { passive: true });
}

// Nav scroll spy
const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');
if (navLinks.length) {
    const sections = [];
    navLinks.forEach(link => {
        const el = document.getElementById(link.getAttribute('href').slice(1));
        if (el) sections.push({ el, link });
    });
    const spyIo = new IntersectionObserver(es => {
        es.forEach(e => {
            const m = sections.find(s => s.el === e.target);
            if (m) m.link.style.color = e.isIntersecting ? 'var(--text)' : '';
        });
    }, { threshold: 0.2, rootMargin: '-56px 0px -50% 0px' });
    sections.forEach(s => spyIo.observe(s.el));
}

// Transparent App — live data
function updateTransparent() {
    const ts = document.getElementById('t-screen');
    const tt = document.getElementById('t-theme');
    if (ts) ts.textContent = `${innerWidth}×${innerHeight}`;
    if (tt) tt.textContent = h.dataset.theme;
}
updateTransparent();
window.addEventListener('resize', updateTransparent);

// rel=noopener
document.querySelectorAll('a[target="_blank"]').forEach(a => a.setAttribute('rel', 'noopener noreferrer'));
