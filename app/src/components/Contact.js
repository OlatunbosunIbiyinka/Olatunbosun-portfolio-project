import React from 'react';

const Contact = () => {
  return (
    <section id="contact" className="section-padding bg-gradient-to-t from-navy/80 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Let's <span className="gradient-text">Connect</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8"></div>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Ready to transform your infrastructure? Let's discuss how I can help 
            build scalable, secure delivery pipelines for your organization.
          </p>
        </div>

        <div className="max-w-4xl mx-auto">
          {/* Contact Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
            {/* Email Card */}
            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-cyan/20 to-blue-600/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"></div>
              
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center">
                <div className="text-5xl mb-4 filter grayscale group-hover:grayscale-0 transition-all duration-300">
                  📧
                </div>
                <h3 className="card-title text-white mb-3 group-hover:text-cyan transition-colors duration-300">
                  Email
                </h3>
                <p className="text-gray-300 mb-6">
                  Get in touch for project discussions, collaboration opportunities, or questions about DevOps best practices.
                </p>
                <a 
                  href="mailto:olatunbosun.ibiyinka@email.com" 
                  className="inline-flex items-center space-x-2 text-cyan hover:text-purple transition-colors duration-300 font-medium group"
                >
                  <span>olatunbosun.ibiyinka@email.com</span>
                  <svg className="w-4 h-4 transform group-hover:translate-x-1 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </a>
              </div>
            </div>

            {/* LinkedIn Card */}
            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-600/20 to-cyan/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"></div>
              
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center">
                <div className="text-5xl mb-4 filter grayscale group-hover:grayscale-0 transition-all duration-300">
                  💼
                </div>
                <h3 className="card-title text-white mb-3 group-hover:text-blue-400 transition-colors duration-300">
                  LinkedIn
                </h3>
                <p className="text-gray-300 mb-6">
                  Connect with me professionally and follow my DevOps journey and career updates.
                </p>
                <a 
                  href="https://www.linkedin.com/in/olatunbosun-ibiyinka-406a6b123/" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="inline-flex items-center space-x-2 text-blue-400 hover:text-cyan transition-colors duration-300 font-medium group"
                >
                  <span>linkedin.com/in/olatunbosun-ibiyinka</span>
                  <svg className="w-4 h-4 transform group-hover:translate-x-1 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              </div>
            </div>

            {/* GitHub Card */}
            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-purple/20 to-pink-600/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"></div>
              
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center">
                <div className="text-5xl mb-4 filter grayscale group-hover:grayscale-0 transition-all duration-300">
                  🐙
                </div>
                <h3 className="card-title text-white mb-3 group-hover:text-purple transition-colors duration-300">
                  GitHub
                </h3>
                <p className="text-gray-300 mb-6">
                  Explore my open-source contributions, infrastructure templates, and automation scripts.
                </p>
                <a 
                  href="https://github.com/OlatunbosunIbiyinka" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="inline-flex items-center space-x-2 text-purple hover:text-cyan transition-colors duration-300 font-medium group"
                >
                  <span>github.com/OlatunbosunIbiyinka</span>
                  <svg className="w-4 h-4 transform group-hover:translate-x-1 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              </div>
            </div>
          </div>

          {/* Availability Status */}
          <div className="card text-center max-w-2xl mx-auto">
            <div className="flex items-center justify-center space-x-3 mb-4">
              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-green-400 font-semibold">Currently Available</span>
            </div>
            <p className="text-gray-300 mb-6">
              I'm actively seeking opportunities to grow as a DevOps engineer and contribute 
              to meaningful infrastructure projects while continuing to learn and develop my skills.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="btn-primary">
                Schedule a Call
              </button>
              <button className="btn-secondary">
                Download Resume
              </button>
            </div>
          </div>

          {/* Footer */}
          <div className="text-center mt-16 pt-8 border-t border-cyan/20">
            <p className="text-gray-400 text-sm">
              Built with React + Tailwind CSS • Deployed on cloud infrastructure
            </p>
            <p className="text-gray-500 text-xs mt-2">
              © 2024 Olatunbosun Ibiyinka. All rights reserved.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Contact;
