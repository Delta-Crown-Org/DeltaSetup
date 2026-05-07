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

  function revealSectionNow(section) {
    if (!section) return;
    section.classList?.add('reveal--visible');
    section.querySelectorAll?.('.reveal').forEach((el) => {
      el.classList.add('reveal--visible');
      revealObserver.unobserve(el);
    });
  }

  function revealHashTarget() {
    const hash = window.location.hash;
    if (!hash || hash.length < 2) return;
    try {
      revealSectionNow(document.querySelector(hash));
    } catch (_) {
      // Ignore invalid hash selectors. Browser hash URLs are chaotic little goblins.
    }
  }

  // Deep links land inside already-built sections. Show that target immediately;
  // do not leave stakeholders staring at pre-reveal ghost content.
  requestAnimationFrame(revealHashTarget);
  window.addEventListener('hashchange', revealHashTarget);

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

  // ---- Sticky Nav (legacy top-nav, only when present) ----
  const nav = document.querySelector('.nav');
  const hero = document.querySelector('.hero');
  const topProgressBar = document.querySelector('.nav__progress');
  const sidebarProgressBar = document.querySelector('.sidebar__progress-bar');

  if (hero) {
    const heroHeight = hero.offsetHeight;

    function updateScroll() {
      const scrollY = window.scrollY;

      if (nav) {
        if (scrollY > heroHeight * 0.3) {
          nav.classList.add('nav--solid');
        } else {
          nav.classList.remove('nav--solid');
        }
      }

      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const percent = docHeight > 0 ? Math.min(100, (scrollY / docHeight) * 100) : 0;
      if (topProgressBar) topProgressBar.style.width = percent + '%';
      if (sidebarProgressBar) sidebarProgressBar.style.width = percent + '%';
    }

    let ticking = false;
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          updateScroll();
          ticking = false;
        });
        ticking = true;
      }
    }, { passive: true });

    updateScroll();
  }

  // ---- Active Nav Link Highlighting (top nav + sidebar) ----
  const sections = document.querySelectorAll('section[id], .section[id]');
  const topNavLinks = document.querySelectorAll('.nav__link');
  const sidebarLinks = document.querySelectorAll('.sidebar__link');

  if (sections.length && (topNavLinks.length || sidebarLinks.length)) {
    const sectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            topNavLinks.forEach((link) => {
              link.classList.toggle(
                'nav__link--active',
                link.getAttribute('href') === '#' + id
              );
            });
            sidebarLinks.forEach((link) => {
              link.classList.toggle(
                'sidebar__link--active',
                link.getAttribute('href') === '#' + id
              );
            });
          }
        });
      },
      { threshold: 0.25, rootMargin: '-80px 0px -40% 0px' }
    );

    sections.forEach((s) => sectionObserver.observe(s));
  }

  // ---- White-glove moment focus ----
  const whitegloveMoments = document.querySelectorAll('.whiteglove__moment');

  if (whitegloveMoments.length) {
    const momentObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          entry.target.classList.toggle('is-active', entry.isIntersecting);
        });
      },
      { threshold: 0.45, rootMargin: '-18% 0px -34% 0px' }
    );

    whitegloveMoments.forEach((moment) => momentObserver.observe(moment));
  }

  // ---- Sidebar mobile toggle ----
  const sidebarToggle = document.querySelector('[data-sidebar-toggle]');
  const sidebarBackdrop = document.querySelector('[data-sidebar-backdrop]');

  function setSidebarOpen(open) {
    document.body.classList.toggle('sidebar-open', open);
    if (sidebarToggle) sidebarToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', () => {
      setSidebarOpen(!document.body.classList.contains('sidebar-open'));
    });
  }
  if (sidebarBackdrop) {
    sidebarBackdrop.addEventListener('click', () => setSidebarOpen(false));
  }
  document.querySelectorAll('.sidebar__link, .sidebar__view').forEach((link) => {
    link.addEventListener('click', () => {
      if (window.matchMedia('(max-width: 1023px)').matches) {
        setSidebarOpen(false);
      }
    });
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && document.body.classList.contains('sidebar-open')) {
      setSidebarOpen(false);
    }
  });

  // ---- Smooth Scroll for Nav Links (motion-respecting) ----
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (e) => {
      const href = link.getAttribute('href');
      if (href === '#' || href.length < 2) return;
      const target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        revealSectionNow(target);
        target.scrollIntoView({
          behavior: reduceMotion ? 'auto' : 'smooth',
          block: 'start'
        });
        if (link.classList.contains('skip-link')) {
          target.focus({ preventScroll: true });
        }
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
