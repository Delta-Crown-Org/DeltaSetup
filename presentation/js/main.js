/**
 * Delta Crown Extensions — Website Controller
 * Scroll-triggered animations, animated counters, sticky nav, progress bar.
 */

(() => {
  'use strict';

  // ---- Scroll Reveal (Intersection Observer) ----
  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('reveal--visible');
          // Only animate once
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
  );

  document.querySelectorAll('.reveal').forEach((el) => {
    revealObserver.observe(el);
  });

  // ---- Animated Number Counters ----
  function animateCounter(el) {
    const target = el.dataset.target;
    const isFloat = target.includes('.');
    const suffix = el.dataset.suffix || '';
    const prefix = el.dataset.prefix || '';
    const end = parseFloat(target);
    const duration = 1800;
    const start = performance.now();

    el.textContent = prefix + '0' + suffix;

    function tick(now) {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = isFloat
        ? (end * eased).toFixed(1)
        : Math.round(end * eased);

      el.textContent = prefix + current + suffix;

      if (progress < 1) {
        requestAnimationFrame(tick);
      } else {
        el.textContent = prefix + target + suffix;
      }
    }
    requestAnimationFrame(tick);
  }

  const counterObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          animateCounter(entry.target);
          counterObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.5 }
  );

  document.querySelectorAll('[data-counter]').forEach((el) => {
    counterObserver.observe(el);
  });

  // ---- Sticky Nav ----
  const nav = document.querySelector('.nav');
  const hero = document.querySelector('.hero');
  const progressBar = document.querySelector('.nav__progress');

  if (nav && hero) {
    const heroHeight = hero.offsetHeight;

    function updateNav() {
      const scrollY = window.scrollY;

      // Solid nav after hero
      if (scrollY > heroHeight * 0.3) {
        nav.classList.add('nav--solid');
      } else {
        nav.classList.remove('nav--solid');
      }

      // Progress bar
      if (progressBar) {
        const docHeight = document.documentElement.scrollHeight - window.innerHeight;
        const percent = docHeight > 0 ? (scrollY / docHeight) * 100 : 0;
        progressBar.style.width = percent + '%';
      }
    }

    // Throttle scroll with rAF
    let ticking = false;
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          updateNav();
          ticking = false;
        });
        ticking = true;
      }
    }, { passive: true });

    updateNav();
  }

  // ---- Active Nav Link Highlighting ----
  const sections = document.querySelectorAll('.section[id]');
  const navLinks = document.querySelectorAll('.nav__link');

  if (sections.length && navLinks.length) {
    const sectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            navLinks.forEach((link) => {
              link.classList.toggle(
                'nav__link--active',
                link.getAttribute('href') === '#' + id
              );
            });
          }
        });
      },
      { threshold: 0.3, rootMargin: '-80px 0px -40% 0px' }
    );

    sections.forEach((s) => sectionObserver.observe(s));
  }

  // ---- Smooth Scroll for Nav Links ----
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (e) => {
      const target = document.querySelector(link.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // ---- Reduce Motion: Skip all animations ----
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.querySelectorAll('.reveal').forEach((el) => {
      el.classList.add('reveal--visible');
    });
    document.querySelectorAll('[data-counter]').forEach((el) => {
      const prefix = el.dataset.prefix || '';
      const suffix = el.dataset.suffix || '';
      el.textContent = prefix + el.dataset.target + suffix;
    });
  }

  // Log
  console.log(
    '%c✦ Delta Crown Extensions',
    'color: #D4A84B; font-size: 14px; font-weight: bold; font-family: serif;'
  );
})();
