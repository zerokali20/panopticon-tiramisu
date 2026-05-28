import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';

const navLinks = [
  { label: 'About', id: 'about' },
  { label: 'System', id: 'system' },
  { label: 'Ethics', id: 'ethics' },
  { label: 'Team', id: 'team' },
  { label: 'Contact', id: 'contact' },
];

function PanopticonNavLogo() {
  return (
    <svg width="32" height="32" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="100" cy="100" r="92" stroke="url(#nl-ring)" strokeWidth="2" strokeDasharray="5 4" />
      <ellipse cx="100" cy="100" rx="58" ry="34" stroke="url(#nl-eye)" strokeWidth="2" fill="none" />
      <circle cx="100" cy="100" r="22" fill="url(#nl-iris)" />
      <circle cx="100" cy="100" r="9" fill="#0a0a1a" />
      <circle cx="100" cy="100" r="4" fill="#38bdf8" />
      <defs>
        <linearGradient id="nl-ring" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#38bdf8" />
          <stop offset="100%" stopColor="#a855f7" />
        </linearGradient>
        <linearGradient id="nl-eye" x1="42" y1="100" x2="158" y2="100" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#38bdf8" stopOpacity="0.6" />
          <stop offset="50%" stopColor="#a855f7" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.6" />
        </linearGradient>
        <radialGradient id="nl-iris" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#1e3a5f" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.3" />
        </radialGradient>
      </defs>
    </svg>
  );
}

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [activeSection, setActiveSection] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => {
      setScrolled(window.scrollY > 40);

      // Highlight active nav
      const sections = navLinks.map(l => l.id);
      let current = '';
      for (const id of sections) {
        const el = document.getElementById(id);
        if (el && window.scrollY >= el.offsetTop - 120) current = id;
      }
      setActiveSection(current);
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const scrollTo = (id) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
    setMenuOpen(false);
  };

  return (
    <>
      <motion.nav
        initial={{ y: -80, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, ease: 'easeOut' }}
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          zIndex: 1000,
          padding: scrolled ? '12px 0' : '20px 0',
          background: scrolled
            ? 'rgba(3, 3, 8, 0.85)'
            : 'transparent',
          backdropFilter: scrolled ? 'blur(20px)' : 'none',
          WebkitBackdropFilter: scrolled ? 'blur(20px)' : 'none',
          borderBottom: scrolled ? '1px solid rgba(56,189,248,0.08)' : 'none',
          transition: 'all 0.4s cubic-bezier(0.4,0,0.2,1)',
        }}
      >
        <div className="container" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          {/* Logo + Wordmark */}
          <button
            onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
            style={{
              display: 'flex', alignItems: 'center', gap: 10,
              background: 'none', border: 'none', cursor: 'pointer',
            }}
          >
            <PanopticonNavLogo />
            <span style={{
              fontFamily: 'var(--font-display)',
              fontSize: '0.95rem',
              fontWeight: 700,
              letterSpacing: '0.12em',
              textTransform: 'uppercase',
              background: 'linear-gradient(135deg, #38bdf8, #a855f7)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}>
              Panopticon
            </span>
          </button>

          {/* Desktop nav links */}
          <div style={{ display: 'flex', gap: 4, alignItems: 'center' }} className="desktop-nav">
            {navLinks.map((link) => (
              <button
                key={link.id}
                onClick={() => scrollTo(link.id)}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '8px 16px',
                  fontFamily: 'var(--font-ui)',
                  fontSize: '0.84rem',
                  fontWeight: 500,
                  letterSpacing: '0.04em',
                  color: activeSection === link.id ? 'var(--accent-blue)' : 'var(--text-muted)',
                  borderRadius: 8,
                  transition: 'all 0.2s ease',
                  textTransform: 'capitalize',
                  position: 'relative',
                }}
                onMouseEnter={e => { if (activeSection !== link.id) e.currentTarget.style.color = 'var(--text-secondary)'; }}
                onMouseLeave={e => { if (activeSection !== link.id) e.currentTarget.style.color = 'var(--text-muted)'; }}
              >
                {link.label}
                {activeSection === link.id && (
                  <motion.div
                    layoutId="nav-indicator"
                    style={{
                      position: 'absolute', bottom: 2, left: '50%',
                      transform: 'translateX(-50%)',
                      width: 16, height: 2,
                      background: 'var(--accent-blue)',
                      borderRadius: 1,
                      boxShadow: '0 0 8px var(--accent-blue)',
                    }}
                  />
                )}
              </button>
            ))}

          </div>

          {/* Mobile hamburger */}
          <button
            className="mobile-menu-btn"
            onClick={() => setMenuOpen(!menuOpen)}
            style={{
              display: 'none',
              flexDirection: 'column',
              gap: 5,
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              padding: 4,
            }}
          >
            {[0, 1, 2].map(i => (
              <div key={i} style={{
                width: 24, height: 2,
                background: 'var(--text-secondary)',
                borderRadius: 1,
                transition: 'all 0.3s',
                transform: menuOpen
                  ? i === 0 ? 'rotate(45deg) translate(5px, 5px)'
                    : i === 2 ? 'rotate(-45deg) translate(5px, -5px)'
                      : 'scaleX(0)'
                  : 'none',
              }} />
            ))}
          </button>
        </div>
      </motion.nav>

      {/* Mobile menu */}
      {menuOpen && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0 }}
          style={{
            position: 'fixed',
            top: 64,
            left: 0,
            right: 0,
            zIndex: 999,
            background: 'rgba(3,3,12,0.97)',
            backdropFilter: 'blur(20px)',
            padding: '20px 24px',
            borderBottom: '1px solid var(--border-glass)',
            display: 'flex',
            flexDirection: 'column',
            gap: 8,
          }}
        >
          {navLinks.map((link) => (
            <button
              key={link.id}
              onClick={() => scrollTo(link.id)}
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                padding: '12px 0',
                fontFamily: 'var(--font-body)',
                fontSize: '1rem',
                color: activeSection === link.id ? 'var(--accent-blue)' : 'var(--text-secondary)',
                textAlign: 'left',
                borderBottom: '1px solid var(--border-glass)',
              }}
            >
              {link.label}
            </button>
          ))}
        </motion.div>
      )}

      <style>{`
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .mobile-menu-btn { display: flex !important; }
        }
      `}</style>
    </>
  );
}
