import Navbar from './components/Navbar';
import Hero from './components/Hero';
import AboutProblem from './components/AboutProblem';
import SystemOverview from './components/SystemOverview';
import EthicalSafeguards from './components/EthicalSafeguards';
import TeamSection from './components/TeamSection';
import ContactSection from './components/ContactSection';
import Footer from './components/Footer';

export default function App() {
  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-deep)' }}>
      <Navbar />
      <main>
        <Hero />
        <AboutProblem />
        <SystemOverview />
        <EthicalSafeguards />
        <TeamSection />
        <ContactSection />
      </main>
      <Footer />
    </div>
  );
}


