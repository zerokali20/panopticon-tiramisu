import GlassCard from './shared/GlassCard';
import SectionTitle from './shared/SectionTitle';
import ScrollReveal from './shared/ScrollReveal';

const stats = [
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        <path d="m9 12 2 2 4-4" />
      </svg>
    ),
    color: '#38bdf8',
    label: 'Reactive Systems Fail',
    stat: '$3.4B+',
    unit: 'lost to vishing in 2024',
    desc: 'Existing solutions only flag calls after the fact — by then, the damage is done. Panopticon intercepts threats in real time, mid-call.',
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="12" cy="12" r="10" />
        <path d="M12 8v4l3 3" />
      </svg>
    ),
    color: '#a855f7',
    label: 'No Real-Time Awareness',
    stat: '240ms',
    unit: 'average detection latency',
    desc: 'Panopticon\'s on-device multi-agent pipeline reasons across live audio, call metadata, and behavioral context simultaneously — no human lag.',
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
        <polyline points="9 22 9 12 15 12 15 22" />
      </svg>
    ),
    color: '#06b6d4',
    label: 'Cloud Violates Privacy',
    stat: '100%',
    unit: 'on-device inference',
    desc: 'Zero audio leaves your device. No cloud dependency, no data brokering. The Zero-Egress Architecture guarantees your conversations stay private.',
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M9 3H5a2 2 0 0 0-2 2v4m6-6h10a2 2 0 0 1 2 2v4M9 3v18m0 0h10a2 2 0 0 0 2-2V9M9 21H5a2 2 0 0 1-2-2V9m0 0h18" />
      </svg>
    ),
    color: '#10b981',
    label: 'Deepfake Audio Surge',
    stat: '3000%',
    unit: 'increase in AI voice cloning (2022–2024)',
    desc: 'Synthetic voices are nearly indistinguishable by the human ear. Panopticon\'s Resemblyzer-based speaker profiling catches clones at the spectral level.',
  },
];

const problemPoints = [
  { text: 'Traditional fraud detection looks at call metadata — not the actual voice content' },
  { text: 'Cloud-based analysis introduces latency and violates call confidentiality' },
  { text: 'Rule-based systems cannot adapt to novel social engineering scripts' },
  { text: 'No existing mobile solution provides live, multi-signal reasoning per call' },
];

export default function AboutProblem() {
  return (
    <section id="about" className="section-pad" style={{
      background: 'linear-gradient(180deg, var(--bg-deep) 0%, #060612 100%)',
      position: 'relative',
    }}>
      {/* Ambient orb */}
      <div className="orb orb-violet" style={{ width: 500, height: 500, top: '10%', right: '-10%', opacity: 0.08 }} />

      <div className="container">
        <SectionTitle
          eyebrow="The Threat Landscape"
          title={<>The Invisible War on <span className="gradient-text">Your Voice</span></>}
          subtitle="Voice phishing and AI-generated deepfake audio represent one of the fastest-growing vectors of financial fraud and social engineering worldwide."
        />

        {/* Stat cards */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
          gap: 24,
          marginBottom: 80,
        }}>
          {stats.map((s, i) => (
            <ScrollReveal key={i} delay={i * 0.12}>
              <GlassCard
                glow
                style={{ padding: '32px 28px', height: '100%' }}
              >
                {/* Icon */}
                <div style={{
                  width: 56, height: 56,
                  borderRadius: 14,
                  background: `linear-gradient(135deg, ${s.color}18, ${s.color}08)`,
                  border: `1px solid ${s.color}28`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 20,
                  color: s.color,
                }}>
                  {s.icon}
                </div>

                {/* Stat callout */}
                <div style={{ marginBottom: 8 }}>
                  <span style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: '2.2rem',
                    fontWeight: 800,
                    color: s.color,
                    textShadow: `0 0 30px ${s.color}50`,
                    lineHeight: 1,
                  }}>{s.stat}</span>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                    {s.unit}
                  </div>
                </div>

                <h3 style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  color: 'var(--text-primary)',
                  letterSpacing: '0.04em',
                  marginBottom: 12,
                  textTransform: 'uppercase',
                }}>
                  {s.label}
                </h3>

                <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', lineHeight: 1.7 }}>
                  {s.desc}
                </p>
              </GlassCard>
            </ScrollReveal>
          ))}
        </div>

        {/* Problem breakdown */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 48, alignItems: 'center' }}>
          <ScrollReveal direction="right">
            <div>
              <h3 style={{
                fontFamily: 'var(--font-display)',
                fontSize: '1.4rem',
                fontWeight: 700,
                marginBottom: 28,
                color: 'var(--text-primary)',
              }}>
                Why existing solutions fall short
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {problemPoints.map((p, i) => (
                  <div key={i} style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
                    <div style={{
                      width: 24, height: 24, borderRadius: '50%',
                      background: 'rgba(168,85,247,0.12)',
                      border: '1px solid rgba(168,85,247,0.3)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      flexShrink: 0, marginTop: 1,
                    }}>
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#a855f7" strokeWidth="3">
                        <line x1="18" y1="6" x2="6" y2="18" />
                        <line x1="6" y1="6" x2="18" y2="18" />
                      </svg>
                    </div>
                    <p style={{ fontSize: '0.92rem', color: 'var(--text-secondary)', lineHeight: 1.65 }}>{p.text}</p>
                  </div>
                ))}
              </div>
            </div>
          </ScrollReveal>

          <ScrollReveal direction="left">
            <GlassCard style={{ padding: '36px 32px' }}>
              <div style={{ textAlign: 'center', marginBottom: 24 }}>
                <div style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '0.72rem',
                  letterSpacing: '0.14em',
                  color: 'var(--accent-cyan)',
                  textTransform: 'uppercase',
                  marginBottom: 8,
                }}>
                  The Panopticon Difference
                </div>
                <h4 style={{ fontSize: '1.2rem', fontWeight: 600, lineHeight: 1.4, color: 'var(--text-primary)' }}>
                  See what others miss,<br />hear what machines fake
                </h4>
              </div>

              {/* Mini feature list */}
              {[
                { icon: '🔴', text: 'Live audio analysis — mid-call, not post-call' },
                { icon: '🧠', text: 'Multi-agent LLM reasoning across all signals' },
                { icon: '🔒', text: 'Zero-egress: no data leaves the device' },
                { icon: '👁', text: 'On-device deepfake voice detection' },
                { icon: '⚡', text: 'Sub-300ms end-to-end response latency' },
              ].map((f, i) => (
                <div key={i} style={{
                  display: 'flex', gap: 12, alignItems: 'center',
                  padding: '10px 0',
                  borderBottom: i < 4 ? '1px solid rgba(255,255,255,0.04)' : 'none',
                }}>
                  <span style={{ fontSize: '1.1rem' }}>{f.icon}</span>
                  <span style={{ fontSize: '0.88rem', color: 'var(--text-secondary)' }}>{f.text}</span>
                </div>
              ))}
            </GlassCard>
          </ScrollReveal>
        </div>
      </div>

      <style>{`
        @media (max-width: 768px) {
          #about .two-col { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </section>
  );
}
