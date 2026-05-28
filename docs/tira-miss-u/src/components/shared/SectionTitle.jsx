import ScrollReveal from './ScrollReveal';

export default function SectionTitle({ eyebrow, title, subtitle, align = 'center', className = '' }) {
  return (
    <div className={`section-title-group ${className}`} style={{ textAlign: align, marginBottom: 64 }}>
      {eyebrow && (
        <ScrollReveal delay={0}>
          <div style={{ display: 'flex', justifyContent: align === 'center' ? 'center' : 'flex-start', marginBottom: 16 }}>
            <span className="badge badge-blue">
              <span style={{
                width: 6, height: 6, borderRadius: '50%', background: 'var(--accent-blue)',
                display: 'inline-block', animation: 'pulse-glow 2s infinite'
              }} />
              {eyebrow}
            </span>
          </div>
        </ScrollReveal>
      )}
      <ScrollReveal delay={0.1}>
        <h2 style={{
          fontFamily: 'var(--font-display)',
          fontSize: 'clamp(2rem, 4vw, 3rem)',
          fontWeight: 700,
          lineHeight: 1.15,
          letterSpacing: '-0.01em',
          marginBottom: 20,
        }}>
          {title}
        </h2>
      </ScrollReveal>
      {subtitle && (
        <ScrollReveal delay={0.2}>
          <p style={{
            fontSize: '1.1rem',
            color: 'var(--text-muted)',
            maxWidth: 600,
            margin: align === 'center' ? '0 auto' : 0,
            lineHeight: 1.75,
          }}>
            {subtitle}
          </p>
        </ScrollReveal>
      )}
    </div>
  );
}
