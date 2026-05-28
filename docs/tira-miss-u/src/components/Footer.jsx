export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer style={{
      background: '#030308',
      borderTop: '1px solid rgba(56,189,248,0.08)',
      padding: '48px 0 32px',
    }}>
      <div className="container">
        {/* Divider glow */}
        <div className="neon-divider" style={{ maxWidth: 600, marginBottom: 40 }} />

        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 24,
          marginBottom: 32,
        }}>
          {/* Logo + wordmark */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <svg width="28" height="28" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="100" cy="100" r="92" stroke="url(#f-ring)" strokeWidth="2" strokeDasharray="5 4" />
              <ellipse cx="100" cy="100" rx="58" ry="34" stroke="url(#f-eye)" strokeWidth="2" fill="none" />
              <circle cx="100" cy="100" r="22" fill="url(#f-iris)" />
              <circle cx="100" cy="100" r="9" fill="#0a0a1a" />
              <circle cx="100" cy="100" r="4" fill="#38bdf8" />
              <defs>
                <linearGradient id="f-ring" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
                  <stop offset="0%" stopColor="#38bdf8" />
                  <stop offset="100%" stopColor="#a855f7" />
                </linearGradient>
                <linearGradient id="f-eye" x1="42" y1="100" x2="158" y2="100" gradientUnits="userSpaceOnUse">
                  <stop offset="0%" stopColor="#38bdf8" stopOpacity="0.6" />
                  <stop offset="50%" stopColor="#a855f7" />
                  <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.6" />
                </linearGradient>
                <radialGradient id="f-iris" cx="50%" cy="50%" r="50%">
                  <stop offset="0%" stopColor="#1e3a5f" />
                  <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.3" />
                </radialGradient>
              </defs>
            </svg>
            <span style={{
              fontFamily: 'var(--font-display)',
              fontSize: '0.9rem', fontWeight: 700,
              letterSpacing: '0.12em', textTransform: 'uppercase',
              background: 'linear-gradient(135deg, #38bdf8, #a855f7)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}>
              Panopticon
            </span>
          </div>

          {/* Quick links */}
          <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
            {['about', 'system', 'ethics', 'team', 'contact'].map(id => (
              <button
                key={id}
                onClick={() => document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' })}
                style={{
                  background: 'none', border: 'none', cursor: 'pointer',
                  fontSize: '0.82rem', color: 'var(--text-muted)',
                  fontFamily: 'var(--font-ui)', textTransform: 'capitalize',
                  transition: 'color 0.2s',
                  padding: 0,
                }}
                onMouseEnter={e => e.currentTarget.style.color = 'var(--text-secondary)'}
                onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
              >
                {id.charAt(0).toUpperCase() + id.slice(1)}
              </button>
            ))}
          </div>

          {/* Badges */}
          <div style={{ display: 'flex', gap: 8 }}>
            <span className="badge badge-blue">AURORA 2026</span>
            <span className="badge badge-violet">AI Ideathon</span>
          </div>
        </div>

        {/* Bottom row */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          flexWrap: 'wrap', gap: 12,
          paddingTop: 24,
          borderTop: '1px solid rgba(255,255,255,0.04)',
        }}>
          <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            © {year} Team Tira-Miss-U · University of Peradeniya
          </p>
          <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            Built for{' '}
            <span style={{ color: 'var(--accent-blue)' }}>AURORA 2026</span>
            {' '}—{' '}
            <span style={{ fontStyle: 'italic' }}>Illuminate. Innovate. Inspire.</span>
          </p>
        </div>
      </div>
    </footer>
  );
}
