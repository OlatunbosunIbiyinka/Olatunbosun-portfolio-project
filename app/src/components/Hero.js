import React from 'react';
import { hasCalendly } from '../config/site';

const Hero = () => {
  return (
    <section
      id="top"
      className="relative min-h-screen flex items-center justify-center bg-cover bg-center overflow-hidden pt-20"
      style={{ backgroundImage: "url('/bg-hero.jpg')" }}
    >
      <div className="absolute inset-0 bg-navy/75" />
      <div className="absolute inset-0 bg-hero-gradient opacity-25" />

      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-32 h-32 bg-cyan/10 rounded-full blur-xl animate-pulse-slow" />
        <div
          className="absolute bottom-20 right-20 w-48 h-48 bg-purple/10 rounded-full blur-xl animate-pulse-slow"
          style={{ animationDelay: '1s' }}
        />
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-cyan/5 rounded-full blur-2xl animate-float" />
      </div>

      <div className="container relative z-10 text-center">
        <p className="text-cyan font-semibold tracking-widest uppercase text-sm mb-2">
          Platform / DevOps Engineer
        </p>
        <p className="text-gray-400 text-sm mb-3">
          Nimbus Compute · Present
        </p>
        <span className="inline-flex items-center gap-2 badge text-green-400 border-green-400/40 mb-8">
          <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
          Open to Platform &amp; DevOps roles
        </span>

        <div className="mb-8">
          <h1 className="hero-title mb-6">
            <span className="block text-white">Olatunbosun</span>
            <span className="block gradient-text">Ibiyinka</span>
          </h1>
          <div className="w-16 sm:w-24 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
        </div>

        <h2 className="text-xl sm:text-2xl lg:text-3xl xl:text-4xl font-bold text-white mb-8 max-w-4xl mx-auto leading-relaxed">
          I help teams ship software{' '}
          <span className="gradient-text">faster, safer, and at scale</span>
        </h2>

        <p className="text-lg sm:text-xl text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
          Cloud infrastructure, CI/CD automation, container platforms, and DevSecOps —
          from first commit to production-ready delivery. Built for reliability,
          security, and teams that need to move with confidence.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
          <a href="#projects" className="btn-primary animate-glow">
            View My Work
          </a>
          {hasCalendly ? (
            <a href="#book-call" className="btn-secondary">
              Book a Call
            </a>
          ) : (
            <a href="#contact" className="btn-secondary">
              Get In Touch
            </a>
          )}
          <a
            href="/cv.pdf"
            download="Olatunbosun_Ibiyinka_Platform_DevOps_Engineer.pdf"
            className="text-cyan hover:text-purple transition-colors font-semibold text-sm underline underline-offset-4"
          >
            Download CV
          </a>
        </div>

        <div className="mt-12 flex flex-wrap justify-center gap-3 max-w-3xl mx-auto">
          {['Terraform', 'Kubernetes', 'CI/CD', 'Azure', 'GitOps', 'DevSecOps'].map((tag) => (
            <span key={tag} className="badge">
              {tag}
            </span>
          ))}
        </div>

        <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
          <div className="w-6 h-10 border-2 border-cyan rounded-full flex justify-center">
            <div className="w-1 h-3 bg-cyan rounded-full mt-2 animate-pulse" />
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
