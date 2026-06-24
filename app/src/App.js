import React from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import About from './components/About';
import Value from './components/Value';
import Skills from './components/Skills';
import Projects from './components/Projects';
import Architecture from './components/Architecture';
import PipelineDiagram from './components/PipelineDiagram';
import Contact from './components/Contact';
import PortfolioAssistant from './components/PortfolioAssistant';

function App() {
  return (
    <div className="App">
      <Navbar />
      <Hero />
      <About />
      <Value />
      <Skills />
      <Projects />
      <Architecture />
      <PipelineDiagram />
      <Contact />
      <PortfolioAssistant />
    </div>
  );
}

export default App;
