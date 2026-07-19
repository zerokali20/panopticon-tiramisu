import { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion, useScroll, useTransform } from 'framer-motion';
import winningPhoto from '../assets/Aurora (2) (1).png';
import secondPhoto from '../assets/second.jpeg';
import thirdPhoto from '../assets/third.jpeg';
import fourthPhoto from '../assets/fourth.jpeg';

// The floating photo animation was removed.
// We now use a cross-fading background layer that cycles through the images.

// ── Add more photos here by importing them and adding them to the array below ──
const BACKGROUND_IMAGES = [
  winningPhoto,
  secondPhoto,
  thirdPhoto,
  fourthPhoto,
];
// Panopticon Eye SVG logo
function PanopticonLogo({ size = 120 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 200 200"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Outer ring */}
      <circle cx="100" cy="100" r="92" stroke="url(#ring-gradient)" strokeWidth="1.5" strokeDasharray="4 3" />
      {/* Middle ring */}
      <circle cx="100" cy="100" r="70" stroke="url(#ring-gradient-2)" strokeWidth="1" opacity="0.5" />
      {/* Eye outer shape */}
      <ellipse
        cx="100" cy="100"
        rx="58" ry="34"
        stroke="url(#eye-gradient)"
        strokeWidth="1.5"
        fill="none"
      />
      {/* Iris */}
      <circle cx="100" cy="100" r="22" fill="url(#iris-gradient)" opacity="0.9" />
      {/* Pupil */}
      <circle cx="100" cy="100" r="9" fill="#0a0a1a" />
      {/* Pupil glow dot */}
      <circle cx="100" cy="100" r="4" fill="url(#pupil-gradient)" />
      {/* Scanning arc top */}
      <path
        d="M 52 100 Q 100 52 148 100"
        stroke="url(#scan-gradient)"
        strokeWidth="1.5"
        fill="none"
        opacity="0.6"
        strokeDasharray="3 4"
      />
      {/* Corner accents */}
      <line x1="20" y1="20" x2="40" y2="20" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="20" y1="20" x2="20" y2="40" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="180" y1="20" x2="160" y2="20" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="180" y1="20" x2="180" y2="40" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="20" y1="180" x2="40" y2="180" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="20" y1="180" x2="20" y2="160" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="180" y1="180" x2="160" y2="180" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      <line x1="180" y1="180" x2="180" y2="160" stroke="#38bdf8" strokeWidth="1.5" opacity="0.5" />
      {/* Waveform bars inside eye */}
      {[0, 1, 2, 3, 4, 5, 6].map((i) => (
        <rect
          key={i}
          x={72 + i * 8}
          y={94 + (i % 2 === 0 ? -8 : -4)}
          width={4}
          height={i % 2 === 0 ? 16 : 12}
          rx={2}
          fill="url(#wave-gradient)"
          opacity={0.6 - i * 0.04}
        />
      ))}
      <defs>
        <linearGradient id="ring-gradient" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#38bdf8" />
          <stop offset="100%" stopColor="#a855f7" />
        </linearGradient>
        <linearGradient id="ring-gradient-2" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#06b6d4" />
          <stop offset="100%" stopColor="#a855f7" />
        </linearGradient>
        <linearGradient id="eye-gradient" x1="42" y1="100" x2="158" y2="100" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#38bdf8" stopOpacity="0.6" />
          <stop offset="50%" stopColor="#a855f7" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.6" />
        </linearGradient>
        <radialGradient id="iris-gradient" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#1e3a5f" />
          <stop offset="60%" stopColor="#0f172a" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0.3" />
        </radialGradient>
        <radialGradient id="pupil-gradient" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#ffffff" />
          <stop offset="100%" stopColor="#38bdf8" />
        </radialGradient>
        <linearGradient id="scan-gradient" x1="52" y1="100" x2="148" y2="100" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#38bdf8" stopOpacity="0" />
          <stop offset="50%" stopColor="#38bdf8" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="wave-gradient" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
          <stop offset="0%" stopColor="#38bdf8" />
          <stop offset="100%" stopColor="#a855f7" />
        </linearGradient>
      </defs>
    </svg>
  );
}

// Animated waveform
export function Waveform({ scale = 1 }) {
  const bars = Array.from({ length: 40 }, (_, i) => i);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 3, height: 50, opacity: 0.5, transform: `scale(${scale})`, transformOrigin: 'left center' }}>
      {bars.map((i) => (
        <div
          key={i}
          style={{
            width: 3,
            borderRadius: 2,
            background: `linear-gradient(180deg, #38bdf8, #a855f7)`,
            animation: `waveform ${0.5 + Math.random() * 0.8}s ease-in-out infinite alternate`,
            animationDelay: `${i * 0.04}s`,
            height: `${20 + Math.sin(i * 0.8) * 16}px`,
          }}
        />
      ))}
    </div>
  );
}

// Floating orb
function FloatingOrb({ color, size, top, left, delay = 0 }) {
  return (
    <div
      className={`orb orb-${color}`}
      style={{
        width: size,
        height: size,
        top,
        left,
        animationDelay: `${delay}s`,
        animation: `float-slow ${6 + delay}s ease-in-out infinite`,
      }}
    />
  );
}

// Premium SaaS-style word reveal animation
function PremiumRevealText({ parts, delay = 0 }) {

  return (
    <motion.span
      initial="hidden"
      animate="visible"
      variants={{
        hidden: { opacity: 1 },
        visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: delay } }
      }}
    >
      {parts.map((part, pIdx) => {
        // Split text into words while keeping the whitespace as separate words to preserve layout
        const words = part.text.split(/(\s+)/);
        return (
          <span key={pIdx} className={part.className}>
            {words.map((word, wIdx) => (
              <motion.span
                key={`${pIdx}-${wIdx}`}
                variants={{
                  hidden: { opacity: 0, y: 12, filter: 'blur(8px)' },
                  visible: { opacity: 1, y: 0, filter: 'blur(0px)', transition: { duration: 0.5, ease: [0.2, 0.65, 0.3, 0.9] } }
                }}
                style={{ display: 'inline-block', whiteSpace: 'pre' }}
              >
                {word}
              </motion.span>
            ))}
          </span>
        );
      })}
    </motion.span>
  );
}

export default function Hero() {
  const [bgIndex, setBgIndex] = useState(0);

  // Cycle through background images every 8 seconds
  useEffect(() => {
    if (BACKGROUND_IMAGES.length <= 1) return;
    const interval = setInterval(() => {
      setBgIndex((prev) => (prev + 1) % BACKGROUND_IMAGES.length);
    }, 8000);
    return () => clearInterval(interval);
  }, []);

  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 600], [0, 120]);
  const opacity = useTransform(scrollY, [0, 400], [1, 0]);
  // Background logo parallax — moves slower than page scroll (backward into screen)
  const bgLogoY = useTransform(scrollY, [0, 600], [0, -80]);
  const bgLogoOpacity = useTransform(scrollY, [0, 500], [0.12, 0]);
  const bgLogoScale = useTransform(scrollY, [0, 600], [1, 1.18]);

  const scrollToSection = (id) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <section
      id="hero"
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        background: 'radial-gradient(ellipse 80% 60% at 50% 0%, rgba(56,189,248,0.07) 0%, transparent 60%), var(--bg-deep)',
      }}
    >
      {/* ── Background Image Layer (Cross-fading Slideshow) ── */}
      <AnimatePresence mode="popLayout">
        <motion.div
          key={bgIndex}
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: `url("${BACKGROUND_IMAGES[bgIndex]}")`,
            backgroundSize: 'contain',
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'center center',
            zIndex: 0,
          }}
          initial={{ opacity: 0, scale: 1.0 }}
          animate={{ opacity: 0.25, scale: 1.03 }}
          exit={{ opacity: 0, scale: 1.0 }}
          transition={{
            opacity: { duration: 1.5, ease: 'easeInOut' },
            scale: { duration: 10, ease: 'linear' },
          }}
        />
      </AnimatePresence>

      {/* Grid background (Overlay to give texture) */}
      <div className="grid-bg" style={{ position: 'absolute', inset: 0, opacity: 0.5, zIndex: 0 }} />


      {/* Atmospheric orbs */}
      <FloatingOrb color="blue" size={600} top="-10%" left="60%" delay={0} />
      <FloatingOrb color="violet" size={500} top="20%" left="-10%" delay={2} />
      <FloatingOrb color="cyan" size={400} top="60%" left="70%" delay={4} />

      {/* Parallax content */}
      <motion.div
        style={{ y, opacity, position: 'relative', zIndex: 1 }}
        className="container"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 32, marginTop: '100px' }}>

          {/* Competition badge */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            style={{ display: 'flex', gap: 12, flexWrap: 'wrap', justifyContent: 'center' }}
          >

          </motion.div>




          {/* Tagline */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.7 }}
            style={{
              fontSize: 'clamp(1.1rem, 2.5vw, 1.4rem)',
              color: 'var(--text-secondary)',
              maxWidth: 620,
              lineHeight: 1.6,
              fontWeight: 300,
              letterSpacing: '0.01em',
              minHeight: '80px', // Prevent layout shift while typing
            }}
          >
            <PremiumRevealText 
              delay={1.0} 
              parts={[
                { text: "Real-time AI defense against", className: "" },
                { text: " ", className: "" },
                { text: "voice phishing", className: "text-neon-blue" },
                { text: " & ", className: "" },
                { text: "deepfake audio", className: "text-neon-violet" },
                { text: ".", className: "" },
                { text: " On-device. Private. Always-on.", className: "" },
              ]}
            />
          </motion.p>

          {/* CTA buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.9 }}
            style={{ display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center' }}
          >
            <button
              className="btn-neon"
              onClick={() => scrollToSection('system')}
              style={{ fontSize: '0.85rem' }}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.35-4.35" />
              </svg>
              Explore the System
            </button>
            <button
              onClick={() => scrollToSection('team')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 8,
                padding: '14px 28px',
                background: 'transparent',
                border: '1px solid rgba(255,255,255,0.12)',
                borderRadius: 50,
                color: 'var(--text-muted)',
                fontFamily: 'var(--font-display)',
                fontSize: '0.82rem',
                fontWeight: 600,
                letterSpacing: '0.08em',
                textTransform: 'uppercase',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
              }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.3)'; e.currentTarget.style.color = '#fff'; }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.12)'; e.currentTarget.style.color = 'var(--text-muted)'; }}
            >
              Meet the Team
            </button>
          </motion.div>

          {/* Team byline */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 1.1 }}
            style={{
              fontSize: '0.78rem',
              color: 'var(--text-muted)',
              letterSpacing: '0.12em',
              textTransform: 'uppercase',
              fontFamily: 'var(--font-ui)',
              minHeight: '20px', // Prevent layout shift
            }}
          >
            <PremiumRevealText 
              delay={1.5} 
              parts={[
                { text: "By ", className: "" },
                { text: "Team Tira-Miss-U", className: "text-neon-blue" },
                { text: " · University of Peradeniya", className: "" },
              ]}
            />
          </motion.p>
        </div>
      </motion.div>



      <style>{`
        @keyframes shimmer {
          0% { background-position: 0% 50%; }
          100% { background-position: 200% 50%; }
        }
        @keyframes waveform {
          0% { transform: scaleY(0.3); }
          100% { transform: scaleY(1); }
        }
      `}</style>
    </section>
  );
}
