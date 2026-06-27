import { useState } from 'react';
import { motion } from 'framer-motion';
import GlassCard from './shared/GlassCard';
import SectionTitle from './shared/SectionTitle';
import ScrollReveal from './shared/ScrollReveal';

function InputGroup({ label, id, type = 'text', placeholder, value, onChange, isTextarea }) {
  const [focused, setFocused] = useState(false);
  const Tag = isTextarea ? 'textarea' : 'input';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <label htmlFor={id} style={{
        fontSize: '0.8rem',
        fontWeight: 500,
        color: focused ? 'var(--accent-blue)' : 'var(--text-muted)',
        letterSpacing: '0.06em',
        textTransform: 'uppercase',
        fontFamily: 'var(--font-ui)',
        transition: 'color 0.2s',
      }}>
        {label}
      </label>
      <Tag
        id={id}
        name={id}
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        className="glass-input"
        rows={isTextarea ? 5 : undefined}
        style={{
          borderColor: focused ? 'rgba(56,189,248,0.4)' : 'var(--border-glass)',
        }}
      />
    </div>
  );
}

export default function ContactSection() {
  const [form, setForm] = useState({ name: '', email: '', subject: '', message: '' });
  const [status, setStatus] = useState(null);

  const handleChange = (e) => setForm(prev => ({ ...prev, [e.target.name]: e.target.value }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setStatus('sending');
    // Formspree integration — replace with your endpoint
    try {
      const res = await fetch('https://formspree.io/f/placeholder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(form),
      });
      setStatus(res.ok ? 'success' : 'error');
    } catch {
      setStatus('error');
    }
  };

  return (
    <section id="contact" className="section-pad" style={{
      background: 'linear-gradient(180deg, #070714 0%, #030308 100%)',
      position: 'relative',
    }}>
      <div className="orb orb-violet" style={{ width: 600, height: 600, top: '0%', left: '-15%', opacity: 0.07 }} />
      <div className="orb orb-blue" style={{ width: 400, height: 400, bottom: '5%', right: '-5%', opacity: 0.07 }} />

      <div className="container">
        <SectionTitle
          eyebrow="Get in Touch"
          title={<>Contact <span className="gradient-text">Team Tira-Miss-U</span></>}
          subtitle="Questions about Panopticon, the AURORA 2026 submission, or research collaboration? We'd love to hear from you."
        />

        <div style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1.4fr',
          gap: 40,
          alignItems: 'start',
        }}
          className="contact-grid"
        >
          {/* Info column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <ScrollReveal direction="right">
              <GlassCard style={{ padding: '28px 24px' }}>
                <div style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '0.75rem', letterSpacing: '0.1em',
                  color: 'var(--accent-blue)', textTransform: 'uppercase',
                  marginBottom: 16,
                }}>
                  About This Project
                </div>
                <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', lineHeight: 1.75 }}>
                  Panopticon is Team Tira-Miss-U's submission to AURORA 2026 — the Inter-University AI Ideathon hosted by the University of Sri Jayewardenepura, Sri Lanka.
                </p>
              </GlassCard>
            </ScrollReveal>

            <ScrollReveal direction="right" delay={0.1}>
              <GlassCard style={{ padding: '28px 24px' }}>
                <div style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '0.75rem', letterSpacing: '0.1em',
                  color: 'var(--accent-violet)', textTransform: 'uppercase',
                  marginBottom: 16,
                }}>
                  Connect
                </div>
                {[
                  {
                    icon: (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                        <polyline points="22,6 12,13 2,6" />
                      </svg>
                    ),
                    label: 'Email',
                    value: 'bhagikaru2003@gmail.com',
                    href: 'mailto:bagikaru2003@gmail.com',
                    color: '#38bdf8',
                  },
                  {
                    icon: (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                      </svg>
                    ),
                    label: 'GitHub',
                    value: 'github.com/tira-miss-u',
                    href: 'https://github.com/imaadh-ifthi/panopticon-tiramisu',
                    color: '#a855f7',
                  },
                  {
                    icon: (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
                      </svg>
                    ),
                    label: 'LinkedIn',
                    value: 'Team Tira-Miss-U',
                    href: '#',
                    color: '#06b6d4',
                  },
                ].map((link, i) => (
                  <a
                    key={i}
                    href={link.href}
                    style={{
                      display: 'flex', alignItems: 'center', gap: 14,
                      padding: '12px 0',
                      borderBottom: i < 2 ? '1px solid rgba(255,255,255,0.05)' : 'none',
                      textDecoration: 'none',
                      color: 'inherit',
                      transition: 'color 0.2s',
                    }}
                    onMouseEnter={e => e.currentTarget.querySelector('.link-value').style.color = link.color}
                    onMouseLeave={e => e.currentTarget.querySelector('.link-value').style.color = 'var(--text-secondary)'}
                  >
                    <div style={{
                      width: 36, height: 36, borderRadius: 8, flexShrink: 0,
                      background: `${link.color}10`, border: `1px solid ${link.color}20`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: link.color,
                    }}>
                      {link.icon}
                    </div>
                    <div>
                      <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{link.label}</div>
                      <div className="link-value" style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', transition: 'color 0.2s' }}>{link.value}</div>
                    </div>
                  </a>
                ))}
              </GlassCard>
            </ScrollReveal>
          </div>

          {/* Form column */}
          <ScrollReveal direction="left" delay={0.1}>
            <GlassCard glow style={{ padding: '40px 36px' }}>
              {status === 'success' ? (
                <motion.div
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  style={{ textAlign: 'center', padding: '40px 0' }}
                >
                  <div style={{ fontSize: '3rem', marginBottom: 16 }}>✅</div>
                  <h3 style={{ fontFamily: 'var(--font-display)', fontSize: '1.2rem', color: 'var(--accent-blue)', marginBottom: 10 }}>
                    Message Sent!
                  </h3>
                  <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                    Thanks for reaching out. We'll get back to you soon.
                  </p>
                  <button
                    onClick={() => { setStatus(null); setForm({ name: '', email: '', subject: '', message: '' }); }}
                    style={{ marginTop: 24, background: 'none', border: 'none', cursor: 'pointer', color: 'var(--accent-blue)', fontSize: '0.85rem' }}
                  >
                    Send another →
                  </button>
                </motion.div>
              ) : (
                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                    <InputGroup label="Name" id="name" placeholder="Your name" value={form.name} onChange={handleChange} />
                    <InputGroup label="Email" id="email" type="email" placeholder="you@example.com" value={form.email} onChange={handleChange} />
                  </div>
                  <InputGroup label="Subject" id="subject" placeholder="What's this about?" value={form.subject} onChange={handleChange} />
                  <InputGroup label="Message" id="message" placeholder="Tell us more..." value={form.message} onChange={handleChange} isTextarea />

                  {status === 'error' && (
                    <p style={{ color: '#f87171', fontSize: '0.85rem' }}>
                      Something went wrong. Please try emailing us directly.
                    </p>
                  )}

                  <button
                    type="submit"
                    className="btn-neon"
                    disabled={status === 'sending'}
                    style={{ alignSelf: 'flex-start', opacity: status === 'sending' ? 0.7 : 1 }}
                  >
                    {status === 'sending' ? (
                      <>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ animation: 'spin-slow 1s linear infinite' }}>
                          <path d="M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z" strokeOpacity="0.3" />
                          <path d="M21 12a9 9 0 0 0-9-9" />
                        </svg>
                        Sending...
                      </>
                    ) : (
                      <>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <line x1="22" y1="2" x2="11" y2="13" />
                          <polygon points="22 2 15 22 11 13 2 9 22 2" />
                        </svg>
                        Send Message
                      </>
                    )}
                  </button>
                </form>
              )}
            </GlassCard>
          </ScrollReveal>
        </div>
      </div>

      <style>{`
        @media (max-width: 768px) {
          .contact-grid { grid-template-columns: 1fr !important; }
        }
        @media (max-width: 480px) {
          .contact-grid form > div:first-child { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </section>
  );
}
