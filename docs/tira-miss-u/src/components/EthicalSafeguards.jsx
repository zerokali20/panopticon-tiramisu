import GlassCard from './shared/GlassCard';
import SectionTitle from './shared/SectionTitle';
import ScrollReveal from './shared/ScrollReveal';

const safeguards = [
  {
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        <path d="M12 8v4" />
        <path d="M12 16h.01" />
      </svg>
    ),
    color: '#38bdf8',
    title: 'Zero-Egress Architecture',
    tag: 'Privacy First',
    desc: 'Every computation — from audio capture to LLM inference — runs entirely on the user\'s device. No audio bytes, transcripts, or metadata are transmitted to any external server. Your conversations are mathematically guaranteed to stay local.',
    points: [
      'No cloud APIs or remote model endpoints',
      'Quantized models via llama.cpp & Whisper.cpp',
      'Offline-capable — works without internet',
    ],
  },
  {
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
    color: '#a855f7',
    title: 'Human-in-the-Loop Design',
    tag: 'Controlled AI',
    desc: 'Panopticon never acts autonomously. Every threat assessment is surfaced as a notification with full context, requiring explicit user confirmation before any protective action is taken. You remain in control at all times.',
    points: [
      'Alert with confidence score & reasoning',
      'User confirms before call blocking or logging',
      'No shadow operations or hidden actions',
    ],
  },
  {
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        <polyline points="9 12 11 14 15 10" />
      </svg>
    ),
    color: '#06b6d4',
    title: 'Honey-Pot Opt-In',
    tag: 'Community Defense',
    desc: 'Users who opt in can contribute to a crowd-sourced vishing intelligence network. Anonymized threat signatures (never audio) are shared via a federated model, strengthening detection for all participants without centralizing any personal data.',
    points: [
      'Federated learning — no raw data shared',
      'Explicit consent required, fully reversible',
      'Anonymous threat-signature contribution only',
    ],
  },
  {
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="12" />
        <line x1="12" y1="16" x2="12.01" y2="16" />
      </svg>
    ),
    color: '#10b981',
    title: 'Reasoning Tree UI',
    tag: 'Explainable AI',
    desc: 'Every threat decision comes with a fully transparent reasoning tree — a structured, human-readable breakdown of exactly which signals triggered the alert, what the LLM inferred, and why. No black-box decisions.',
    points: [
      'Visual decision tree per alert event',
      'Shows audio anomalies, transcript flags, metadata',
      'User can audit, contest, or dismiss any decision',
    ],
  },
];

export default function EthicalSafeguards() {
  return (
    <section id="ethics" className="section-pad" style={{
      background: 'linear-gradient(180deg, #080818 0%, #060610 100%)',
      position: 'relative',
    }}>
      <div className="orb orb-violet" style={{ width: 500, height: 500, top: '20%', right: '-5%', opacity: 0.07 }} />
      <div className="orb orb-cyan" style={{ width: 400, height: 400, bottom: '0%', left: '-10%', opacity: 0.06 }} />

      <div className="container">
        <SectionTitle
          eyebrow="Ethical Framework"
          title={<>Built with <span className="gradient-text-cyan">Responsibility</span> in Mind</>}
          subtitle="Panopticon is designed from first principles to be privacy-preserving, transparent, and always deferential to human judgment."
        />

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: 24,
        }}>
          {safeguards.map((s, i) => (
            <ScrollReveal key={i} delay={i * 0.12}>
              <GlassCard
                glow
                style={{
                  padding: '36px 28px',
                  height: '100%',
                  borderColor: `${s.color}18`,
                  position: 'relative',
                  overflow: 'hidden',
                }}
              >
                {/* Subtle corner accent */}
                <div style={{
                  position: 'absolute', top: 0, right: 0,
                  width: 80, height: 80,
                  background: `radial-gradient(circle at top right, ${s.color}12, transparent 70%)`,
                  pointerEvents: 'none',
                }} />

                {/* Icon */}
                <div style={{
                  width: 64, height: 64, borderRadius: 18,
                  background: `linear-gradient(135deg, ${s.color}15, ${s.color}05)`,
                  border: `1px solid ${s.color}25`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: s.color, marginBottom: 20,
                  boxShadow: `0 0 20px ${s.color}18`,
                }}>
                  {s.icon}
                </div>

                {/* Tag */}
                <div style={{ marginBottom: 10 }}>
                  <span style={{
                    fontSize: '0.65rem', fontFamily: 'var(--font-display)',
                    letterSpacing: '0.14em', textTransform: 'uppercase',
                    color: s.color, fontWeight: 600,
                  }}>
                    {s.tag}
                  </span>
                </div>

                {/* Title */}
                <h3 style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '1rem', fontWeight: 700,
                  color: 'var(--text-primary)', lineHeight: 1.3,
                  marginBottom: 14, letterSpacing: '0.01em',
                }}>
                  {s.title}
                </h3>

                {/* Description */}
                <p style={{
                  fontSize: '0.87rem', color: 'var(--text-muted)',
                  lineHeight: 1.75, marginBottom: 20,
                }}>
                  {s.desc}
                </p>

                {/* Points */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                  {s.points.map((p, j) => (
                    <div key={j} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                      <div style={{
                        width: 18, height: 18, borderRadius: '50%',
                        background: `${s.color}15`,
                        border: `1px solid ${s.color}30`,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        flexShrink: 0, marginTop: 1,
                      }}>
                        <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke={s.color} strokeWidth="3">
                          <polyline points="20 6 9 17 4 12" />
                        </svg>
                      </div>
                      <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.55 }}>{p}</span>
                    </div>
                  ))}
                </div>
              </GlassCard>
            </ScrollReveal>
          ))}
        </div>

        {/* Ethics statement */}
        <ScrollReveal delay={0.3}>
          <div style={{
            marginTop: 64,
            padding: '32px 40px',
            background: 'linear-gradient(135deg, rgba(56,189,248,0.05), rgba(168,85,247,0.05))',
            border: '1px solid rgba(56,189,248,0.12)',
            borderRadius: 20,
            textAlign: 'center',
          }}>
            <div style={{
              fontSize: '1.2rem', fontWeight: 500,
              color: 'var(--text-secondary)', lineHeight: 1.7,
              fontStyle: 'italic',
            }}>
              "Panopticon sees all — but only to protect. Never to surveil."
            </div>
            <div style={{
              marginTop: 12, fontSize: '0.78rem',
              color: 'var(--text-muted)', letterSpacing: '0.06em',
              textTransform: 'uppercase', fontFamily: 'var(--font-display)',
            }}>
              Team Tira-Miss-U — Design Principle
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
