import React from 'react';

const Hero = () => {
  return (
    <section 
      className="relative h-screen flex items-center justify-center bg-cover bg-center overflow-hidden"
      style={{ backgroundImage: "url('/bg-hero.jpg')" }}
    >
      {/* Dark overlay for text readability */}
      <div className="absolute inset-0 bg-black/70"></div>
      
      {/* Subtle gradient overlay blending with background */}
      <div className="absolute inset-0 bg-hero-gradient opacity-30"></div>
      
      {/* Animated Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-32 h-32 bg-cyan/10 rounded-full blur-xl animate-pulse-slow"></div>
        <div className="absolute bottom-20 right-20 w-48 h-48 bg-purple/10 rounded-full blur-xl animate-pulse-slow" style={{animationDelay: '1s'}}></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-cyan/5 rounded-full blur-2xl animate-float"></div>
      </div>
      
      {/* Main Content */}
      <div className="container relative z-10 text-center">
        <div className="mb-8">
          <h1 className="hero-title mb-6">
            <span className="block text-white">Olatunbosun</span>
            <span className="block gradient-text">Ibiyinka</span>
          </h1>
          <div className="w-16 sm:w-24 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8"></div>
        </div>
        
        <h2 className="text-xl sm:text-2xl lg:text-3xl xl:text-4xl font-bold text-white mb-8 max-w-4xl mx-auto leading-relaxed">
          I build secure, observable delivery pipelines that{' '}
          <span className="gradient-text">scale</span>
        </h2>
        
        <p className="text-lg sm:text-xl text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
          Emerging DevOps Engineer passionate about Azure cloud infrastructure, automation, 
          and collaborative development practices that drive modern software delivery.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
          <button className="btn-primary animate-glow">
            View My Work
          </button>
          <button className="btn-secondary">
            Get In Touch
          </button>
        </div>
        
        {/* Scroll Indicator */}
        <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
          <div className="w-6 h-10 border-2 border-cyan rounded-full flex justify-center">
            <div className="w-1 h-3 bg-cyan rounded-full mt-2 animate-pulse"></div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
