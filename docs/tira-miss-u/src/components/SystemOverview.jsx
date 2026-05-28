import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import GlassCard from './shared/GlassCard';
import SectionTitle from './shared/SectionTitle';
import ScrollReveal from './shared/ScrollReveal';

const pipeline = [
  {
    id: '01',
    layer: 'Perception',
    title: 'Signal Acquisition',
    color: '#38bdf8',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z" />
        <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
        <line x1="12" y1="19" x2="12" y2="22" />
        <line x1="8" y1="22" x2="16" y2="22" />
      </svg>
    ),
    points: [
      'RNNoise — real-time noise suppression from raw call audio',
      'Whisper.cpp — on-device speech-to-text transcription',
      'Resemblyzer — speaker embedding & voice fingerprinting',
      'Call metadata extraction (duration, frequency, source)',
    ],
    tech: ['Whisper.cpp', 'RNNoise', 'Resemblyzer'],
  },
  {
    id: '02',
    layer: 'Reasoning',
    title: 'Multi-Agent Analysis',
    color: '#a855f7',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
        <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
        <line x1="12" y1="22.08" x2="12" y2="12" />
      </svg>
    ),
    points: [
      'llama.cpp — quantized on-device LLM for conversation analysis',
      'Threat Scorer Agent — synthesizes all signals into risk score',
      'Context Agent — maintains per-call conversation state',
      'Anomaly Detector — flags deepfake speech patterns',
    ],
    tech: ['llama.cpp', 'ObjectBox'],
  },
  {
    id: '03',
    layer: 'Action',
    title: 'Intervention & Alerting',
    color: '#06b6d4',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M18 8h1a4 4 0 0 1 0 8h-1" />
        <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
        <line x1="6" y1="1" x2="6" y2="4" />
        <line x1="10" y1="1" x2="10" y2="4" />
        <line x1="14" y1="1" x2="14" y2="4" />
      </svg>
    ),
    points: [
      'Real-time overlays in Flutter UI with threat confidence score',
      'Human-in-the-loop confirmation before any blocking action',
      'Reasoning Tree UI — transparent, explainable AI decisions',
      'Local audit log stored in ObjectBox (zero-cloud)',
    ],
    tech: ['Flutter', 'ObjectBox'],
  },
];

const techStack = [
  { name: 'Flutter', role: 'Cross-platform mobile UI', color: '#38bdf8', icon: '📱' },
  { name: 'llama.cpp', role: 'On-device LLM inference', color: '#a855f7', icon: '🧠' },
  { name: 'Whisper.cpp', role: 'Speech-to-text transcription', color: '#06b6d4', icon: '🎙️' },
  { name: 'ObjectBox', role: 'Embedded vector database', color: '#10b981', icon: '🗄️' },
  { name: 'RNNoise', role: 'Neural noise suppression', color: '#f59e0b', icon: '🔇' },
  { name: 'Resemblyzer', role: 'Speaker voice embeddings', color: '#ec4899', icon: '👤' },
];

function PipelineConnector({ color }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', margin: '8px 0' }}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
        <div style={{ width: 2, height: 24, background: `linear-gradient(180deg, ${color}, transparent)`, opacity: 0.5 }} />
        <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
          <path d="M8 10L0 0h16L8 10z" fill={color} opacity="0.5" />
        </svg>
      </div>
    </div>
  );
}

// Architecture flow diagram (SVG)
function ArchDiagram() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });

  const nodes = [
    { label: 'Raw Audio', x: 60, y: 50, color: '#475569' },
    { label: 'RNNoise', x: 200, y: 50, color: '#38bdf8' },
    { label: 'Whisper.cpp', x: 340, y: 20, color: '#38bdf8' },
    { label: 'Resemblyzer', x: 340, y: 80, color: '#38bdf8' },
    { label: 'LLM Agent\n(llama.cpp)', x: 490, y: 50, color: '#a855f7' },
    { label: 'ObjectBox', x: 490, y: 110, color: '#10b981' },
    { label: 'Flutter UI', x: 630, y: 50, color: '#06b6d4' },
    { label: 'Alert /\nReasoning Tree', x: 630, y: 110, color: '#06b6d4' },
  ];

  return (
    <div ref={ref} style={{ overflowX: 'auto', padding: '8px 0' }}>
      <svg
        viewBox="0 0 720 160"
        style={{ width: '100%', minWidth: 600, height: 'auto' }}
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Connection lines */}
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, ease: 'easeInOut' }}
          d="M 110 50 L 160 50" stroke="#475569" strokeWidth="1.5" fill="none" markerEnd="url(#arrow)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.2 }}
          d="M 250 50 L 295 30" stroke="#38bdf8" strokeWidth="1.5" fill="none" opacity="0.6" markerEnd="url(#arrow-blue)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.3 }}
          d="M 250 50 L 295 80" stroke="#38bdf8" strokeWidth="1.5" fill="none" opacity="0.6" markerEnd="url(#arrow-blue)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.5 }}
          d="M 400 30 L 445 50" stroke="#38bdf8" strokeWidth="1.5" fill="none" opacity="0.6" markerEnd="url(#arrow-blue)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.6 }}
          d="M 400 80 L 445 55" stroke="#38bdf8" strokeWidth="1.5" fill="none" opacity="0.6" markerEnd="url(#arrow-blue)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.8 }}
          d="M 545 50 L 595 50" stroke="#a855f7" strokeWidth="1.5" fill="none" opacity="0.7" markerEnd="url(#arrow-violet)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 0.9 }}
          d="M 545 55 L 595 100" stroke="#a855f7" strokeWidth="1.5" fill="none" opacity="0.4" markerEnd="url(#arrow-violet)" />
        <motion.path initial={{ pathLength: 0 }} animate={inView ? { pathLength: 1 } : {}} transition={{ duration: 1.5, delay: 1 }}
          d="M 545 115 L 595 55" stroke="#10b981" strokeWidth="1.5" fill="none" opacity="0.4" markerEnd="url(#arrow-green)" />

        {/* Layer labels */}
        {['PERCEPTION', 'REASONING', 'ACTION'].map((l, i) => (
          <text key={l} x={200 + i * 140 + (i === 0 ? 0 : i === 1 ? 15 : 5)} y={148} fill={['#38bdf8', '#a855f7', '#06b6d4'][i]}
            fontSize="7" fontFamily="Orbitron, sans-serif" textAnchor="middle" opacity="0.6" letterSpacing="2">
            {l}
          </text>
        ))}

        {/* Layer dividers */}
        <line x1="275" y1="0" x2="275" y2="135" stroke="rgba(255,255,255,0.06)" strokeWidth="1" strokeDasharray="4 3" />
        <line x1="425" y1="0" x2="425" y2="135" stroke="rgba(255,255,255,0.06)" strokeWidth="1" strokeDasharray="4 3" />
        <line x1="575" y1="0" x2="575" y2="135" stroke="rgba(255,255,255,0.06)" strokeWidth="1" strokeDasharray="4 3" />

        {/* Nodes */}
        {nodes.map((node, i) => (
          <motion.g key={i} initial={{ opacity: 0, scale: 0.7 }} animate={inView ? { opacity: 1, scale: 1 } : {}} transition={{ delay: i * 0.1 + 0.3 }}>
            <rect x={node.x - 48} y={node.y - 14} width={96} height={28} rx={6} fill={`${node.color}18`} stroke={node.color} strokeWidth="1" opacity="0.9" />
            {node.label.split('\n').map((line, li) => (
              <text key={li} x={node.x} y={node.y - 1 + li * 10} fill={node.color} fontSize="7.5" fontFamily="Space Grotesk, sans-serif" textAnchor="middle" fontWeight="500">
                {line}
              </text>
            ))}
          </motion.g>
        ))}

        <defs>
          <marker id="arrow" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto">
            <path d="M0,0 L0,6 L6,3 z" fill="#475569" />
          </marker>
          <marker id="arrow-blue" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto">
            <path d="M0,0 L0,6 L6,3 z" fill="#38bdf8" />
          </marker>
          <marker id="arrow-violet" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto">
            <path d="M0,0 L0,6 L6,3 z" fill="#a855f7" />
          </marker>
          <marker id="arrow-green" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto">
            <path d="M0,0 L0,6 L6,3 z" fill="#10b981" />
          </marker>
        </defs>
      </svg>
    </div>
  );
}

export default function SystemOverview() {
  return (
    <section id="system" className="section-pad" style={{
      background: 'linear-gradient(180deg, #060612 0%, #080818 100%)',
      position: 'relative',
    }}>
      <div className="orb orb-blue" style={{ width: 600, height: 600, top: '5%', left: '-15%', opacity: 0.06 }} />

      <div className="container">
        <SectionTitle
          eyebrow="System Architecture"
          title={<>Three-Layer AI <span className="gradient-text">Pipeline</span></>}
          subtitle="Panopticon processes every call through a layered multi-agent stack — from raw audio to actionable threat intelligence — entirely on your device."
        />

        {/* Architecture diagram */}
        <ScrollReveal>
          <GlassCard style={{ padding: '32px 24px', marginBottom: 64 }}>
            <div style={{
              fontSize: '0.72rem', fontFamily: 'var(--font-display)',
              letterSpacing: '0.12em', color: 'var(--text-muted)',
              textTransform: 'uppercase', marginBottom: 20, textAlign: 'center',
            }}>
              Architecture Flowchart
            </div>
            <ArchDiagram />
          </GlassCard>
        </ScrollReveal>

        {/* Pipeline layers */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 72 }}>
          {pipeline.map((layer, i) => (
            <div key={layer.id}>
              <ScrollReveal delay={i * 0.15}>
                <GlassCard glow style={{ padding: '36px 32px' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 24, alignItems: 'start' }}>
                    <div>
                      {/* Layer header */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
                        <div style={{
                          width: 52, height: 52, borderRadius: 14,
                          background: `linear-gradient(135deg, ${layer.color}20, ${layer.color}08)`,
                          border: `1px solid ${layer.color}30`,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          color: layer.color, flexShrink: 0,
                        }}>
                          {layer.icon}
                        </div>
                        <div>
                          <div style={{
                            fontFamily: 'var(--font-display)',
                            fontSize: '0.65rem', fontWeight: 700,
                            letterSpacing: '0.18em', textTransform: 'uppercase',
                            color: layer.color, marginBottom: 4,
                          }}>
                            Layer {layer.id} — {layer.layer}
                          </div>
                          <h3 style={{
                            fontFamily: 'var(--font-display)',
                            fontSize: '1.2rem', fontWeight: 700,
                            color: 'var(--text-primary)', lineHeight: 1.2,
                          }}>
                            {layer.title}
                          </h3>
                        </div>
                      </div>

                      {/* Points */}
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                        {layer.points.map((p, j) => (
                          <div key={j} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                            <div style={{
                              width: 6, height: 6, borderRadius: '50%',
                              background: layer.color, flexShrink: 0, marginTop: 6,
                              boxShadow: `0 0 8px ${layer.color}`,
                            }} />
                            <span style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', lineHeight: 1.6 }}>{p}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Tech pills */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minWidth: 120 }}>
                      {layer.tech.map(t => (
                        <span key={t} className="tech-pill" style={{
                          fontSize: '0.72rem',
                          borderColor: `${layer.color}25`,
                          color: layer.color,
                          background: `${layer.color}08`,
                        }}>
                          {t}
                        </span>
                      ))}
                    </div>
                  </div>
                </GlassCard>
              </ScrollReveal>
              {i < pipeline.length - 1 && <PipelineConnector color={pipeline[i].color} />}
            </div>
          ))}
        </div>

        {/* Tech stack grid */}
        <ScrollReveal>
          <div style={{ marginBottom: 32, textAlign: 'center' }}>
            <span className="badge badge-blue">Technology Stack</span>
          </div>
        </ScrollReveal>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 16,
        }}>
          {techStack.map((tech, i) => (
            <ScrollReveal key={i} delay={i * 0.08}>
              <GlassCard style={{ padding: '24px 20px', textAlign: 'center' }}>
                <div style={{ fontSize: '2rem', marginBottom: 12 }}>{tech.icon}</div>
                <div style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '0.85rem', fontWeight: 700,
                  color: tech.color, marginBottom: 6,
                  letterSpacing: '0.04em',
                }}>
                  {tech.name}
                </div>
                <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>
                  {tech.role}
                </div>
              </GlassCard>
            </ScrollReveal>
          ))}
        </div>
      </div>

      <style>{`
        @media (max-width: 640px) {
          #system .pipeline-grid { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </section>
  );
}
