import { useState } from 'react';
import SectionTitle from './shared/SectionTitle';
import ScrollReveal from './shared/ScrollReveal';


// Team member photos
import photoImaadh from '../assets/Imaadh Ifthikar.jpg';
import photoRashad from '../assets/Rashad Shamil.jpg';
import photoBhagya from '../assets/Bhagya Karunanayake.jpeg';
import photoKishonithan from '../assets/S. Kishonithan.jpeg';

const members = [
  {
    name: 'M.I.M. Imaadh',
    photo: photoImaadh,
    role: 'AI/ML Engineer',
    color: '#38bdf8',
    bio: 'Specializes in on-device LLM deployment and multi-agent system design. Lead architect of the Reasoning layer.',
    skills: ['llama.cpp', 'quantisation', 'Local LLM'],
    github: 'https://github.com/imaadh-ifthi',
    linkedin: 'https://www.linkedin.com/in/imaadh-ifthikar-the-computer-engineer',
    email: '#',
  },
  {
    name: 'Rashad Shamil',
    photo: photoRashad,
    role: 'Mobile & Systems Engineer',
    color: '#a855f7',
    bio: 'Leads Flutter app development and on-device inference optimization. Architect of the Zero-Egress mobile pipeline and Work with Local LLM.',
    skills: ['Whisper.cpp', 'App Framework', 'Dart', 'ObjectBox'],
    github: 'https://github.com/RashadShamil',
    linkedin: 'https://www.linkedin.com/in/rashadshamil/',
    email: '#',
  },
  {
    name: 'Bhagya Karunanayake',
    photo: photoBhagya,
    role: 'IR & NLP Engineer',
    color: '#06b6d4',
    bio: 'Expert in audio ML pipelines,RAG system, ethical AI frameworks and speaker verification systems using deep learning embeddings.',
    skills: ['RAG', 'VectorDB', 'LlamaIndex', 'RNNoise'],
    github: 'https://github.com/zerokali20',
    linkedin: 'https://www.linkedin.com/in/bhagya-karunanayake-b52085270',
    email: '#',
  },
  {
    name: 'S. Kishonithan',
    photo: photoKishonithan,
    role: 'Defensive ML Engineer',
    color: '#10b981',
    bio: 'Focuses on threat modeling,Proposed High-Level Audio Pipeline,noise suppression and the Honey-Pot federated intelligence architecture.',
    skills: ['audio recognition', 'Privacy', 'Federated ML'],
    github: 'https://github.com/kisho19',
    linkedin: 'https://www.linkedin.com/in/kishonithan-suntharalingam-2444012b7/',
    email: '#',
  },
];

function SocialIcon({ type, href }) {
  const icons = {
    github: (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
      </svg>
    ),
    linkedin: (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
      </svg>
    ),
    email: (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
        <polyline points="22,6 12,13 2,6" />
      </svg>
    ),
  };

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        width: 34, height: 34, borderRadius: 8,
        background: 'rgba(255,255,255,0.04)',
        border: '1px solid rgba(255,255,255,0.08)',
        color: 'var(--text-muted)',
        transition: 'all 0.25s ease',
        textDecoration: 'none',
      }}
      onMouseEnter={e => {
        e.currentTarget.style.background = 'rgba(56,189,248,0.1)';
        e.currentTarget.style.borderColor = 'rgba(56,189,248,0.3)';
        e.currentTarget.style.color = 'var(--accent-blue)';
      }}
      onMouseLeave={e => {
        e.currentTarget.style.background = 'rgba(255,255,255,0.04)';
        e.currentTarget.style.borderColor = 'rgba(255,255,255,0.08)';
        e.currentTarget.style.color = 'var(--text-muted)';
      }}
    >
      {icons[type]}
    </a>
  );
}

function MemberCard({ member, index }) {
  const [hovered, setHovered] = useState(false);

  return (
    <ScrollReveal delay={index * 0.12}>
      <div
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        style={{
          padding: '32px 24px',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          transform: hovered ? 'translateY(-8px)' : 'translateY(0)',
          transition: 'transform 0.35s cubic-bezier(0.4,0,0.2,1)',
        }}
      >
        {/* Avatar */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 24 }}>
          {/* Outer glow ring */}
          <div style={{
            padding: 3,
            borderRadius: '50%',
            background: hovered
              ? `linear-gradient(135deg, ${member.color}, ${member.color}60)`
              : `linear-gradient(135deg, ${member.color}50, ${member.color}20)`,
            boxShadow: hovered ? `0 0 28px ${member.color}60, 0 0 60px ${member.color}25` : 'none',
            transition: 'all 0.4s cubic-bezier(0.4,0,0.2,1)',
            marginBottom: 4,
          }}>
            <div style={{
              width: 96, height: 96,
              borderRadius: '50%',
              overflow: 'hidden',
              background: `linear-gradient(135deg, ${member.color}20, #0a0a1a)`,
              border: '2px solid #030308',
              position: 'relative',
            }}>
              <img
                src={member.photo}
                alt={member.name}
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  objectPosition: 'center top',
                  display: 'block',
                  filter: hovered ? 'brightness(1.08) saturate(1.1)' : 'brightness(0.95)',
                  transition: 'filter 0.35s ease, transform 0.4s ease',
                  transform: hovered ? 'scale(1.05)' : 'scale(1)',
                }}
              />
            </div>
          </div>
        </div>

        {/* Name & Role */}
        <div style={{ textAlign: 'center', marginBottom: 16 }}>
          <h3 style={{
            fontFamily: 'var(--font-display)',
            fontSize: '0.95rem', fontWeight: 700,
            color: 'var(--text-primary)', marginBottom: 6,
            letterSpacing: '0.02em',
          }}>
            {member.name}
          </h3>
          <div style={{
            fontSize: '0.75rem', fontWeight: 600,
            color: member.color, letterSpacing: '0.1em',
            textTransform: 'uppercase', fontFamily: 'var(--font-ui)',
          }}>
            {member.role}
          </div>
        </div>

        {/* Bio */}
        <p style={{
          fontSize: '0.85rem', color: 'var(--text-muted)',
          lineHeight: 1.7, textAlign: 'center', marginBottom: 20,
          flexGrow: 1,
        }}>
          {member.bio}
        </p>

        {/* Skills */}
        <div style={{
          display: 'flex', gap: 6, flexWrap: 'wrap',
          justifyContent: 'center', marginBottom: 20,
        }}>
          {member.skills.map(s => (
            <span key={s} style={{
              padding: '3px 10px',
              borderRadius: 20,
              fontSize: '0.7rem', fontWeight: 500,
              background: `${member.color}10`,
              border: `1px solid ${member.color}20`,
              color: member.color,
              fontFamily: 'var(--font-ui)',
            }}>
              {s}
            </span>
          ))}
        </div>

        {/* Social links */}
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
          <SocialIcon type="github" href={member.github} />
          <SocialIcon type="linkedin" href={member.linkedin} />
          <SocialIcon type="email" href={member.email} />
        </div>
      </div>
    </ScrollReveal>
  );
}

export default function TeamSection() {
  return (
    <section id="team" className="section-pad" style={{
      background: 'linear-gradient(180deg, #060610 0%, #070714 100%)',
      position: 'relative',
    }}>
      <div className="orb orb-blue" style={{ width: 500, height: 500, bottom: '-5%', right: '-10%', opacity: 0.07 }} />

      <div className="container">
        <SectionTitle
          eyebrow="Team Tira-Miss-U"
          title={<>The Minds Behind <span className="gradient-text">Panopticon</span></>}
          subtitle="Undergraduate students at the University of Peradeniya, competing at AURORA 2026 — the Inter-University AI Ideathon."
        />

        {/* Competition strip */}
        <ScrollReveal>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 24,
            marginBottom: 56,
            padding: '16px 32px',
            background: 'linear-gradient(135deg, rgba(56,189,248,0.05), rgba(168,85,247,0.05))',
            border: '1px solid rgba(56,189,248,0.1)',
            borderRadius: 16,
            flexWrap: 'wrap',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 8,
                background: 'rgba(56,189,248,0.1)',
                border: '1px solid rgba(56,189,248,0.2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--accent-blue)',
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                </svg>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', letterSpacing: '0.06em' }}>Competition</div>
                <div style={{ fontSize: '0.9rem', fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'var(--font-display)' }}>AURORA 2026</div>
              </div>
            </div>
            <div style={{ width: 1, height: 32, background: 'var(--border-glass)' }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 8,
                background: 'rgba(168,85,247,0.1)',
                border: '1px solid rgba(168,85,247,0.2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--accent-violet)',
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                </svg>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', letterSpacing: '0.06em' }}>Institution</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)' }}>University of Peradeniya</div>
              </div>
            </div>
            <div style={{ width: 1, height: 32, background: 'var(--border-glass)' }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 8,
                background: 'rgba(6,182,212,0.1)',
                border: '1px solid rgba(6,182,212,0.2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--accent-cyan)',
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                  <circle cx="9" cy="7" r="4" />
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                  <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                </svg>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', letterSpacing: '0.06em' }}>Team</div>
                <div style={{ fontSize: '0.9rem', fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'var(--font-display)' }}>Tira-Miss-U · 4 Members</div>
              </div>
            </div>
          </div>
        </ScrollReveal>

        {/* Member cards */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: 24,
        }}>
          {members.map((m, i) => (
            <MemberCard key={m.name} member={m} index={i} />
          ))}
        </div>

        {/* Photo credit note removed — real photos now active */}
      </div>
    </section>
  );
}
