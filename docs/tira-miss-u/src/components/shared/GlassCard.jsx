import { motion } from 'framer-motion';

export default function GlassCard({ children, className = '', style = {}, hover = true, glow = false }) {
  return (
    <motion.div
      whileHover={hover ? { y: -6, scale: 1.01 } : undefined}
      transition={{ type: 'spring', stiffness: 300, damping: 20 }}
      className={`glass-card ${className}`}
      style={{
        boxShadow: glow
          ? '0 0 40px rgba(56,189,248,0.08), 0 4px 40px rgba(0,0,0,0.4)'
          : '0 4px 40px rgba(0,0,0,0.35)',
        ...style,
      }}
    >
      {children}
    </motion.div>
  );
}
