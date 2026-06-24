import React from 'react';
import CalendlyEmbed from './CalendlyEmbed';
import { calendlyUrl, hasCalendly } from '../config/site';

const Contact = () => {
  return (
    <section id="contact" className="section-padding bg-gradient-to-t from-navy/80 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Let&apos;s <span className="gradient-text">Connect</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Whether you&apos;re hiring, building a platform team, or modernising how your organisation
            delivers software — I&apos;d like to hear from you.
          </p>
        </div>

        <div className="max-w-4xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-16">
            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-cyan/20 to-blue-600/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center h-full">
                <div className="text-5xl mb-4">📧</div>
                <h3 className="card-title text-white mb-3 group-hover:text-cyan transition-colors">Email</h3>
                <p className="text-gray-300 mb-6 text-sm">
                  Roles, contracts, collaborations, or a conversation about your delivery challenges.
                </p>
                <a
                  href="mailto:olatunbosunkayode47@gmail.com"
                  className="inline-flex items-center gap-2 text-cyan hover:text-purple transition-colors font-medium text-sm break-all"
                >
                  olatunbosunkayode47@gmail.com
                </a>
              </div>
            </div>

            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-600/20 to-cyan/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center h-full">
                <div className="text-5xl mb-4">💼</div>
                <h3 className="card-title text-white mb-3 group-hover:text-blue-400 transition-colors">LinkedIn</h3>
                <p className="text-gray-300 mb-6 text-sm">
                  Connect professionally — DevOps, cloud engineering, and platform delivery.
                </p>
                <a
                  href="https://www.linkedin.com/in/olatunbosun-ibiyinka-406a6b123/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-blue-400 hover:text-cyan transition-colors font-medium text-sm"
                >
                  LinkedIn Profile
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                    />
                  </svg>
                </a>
              </div>
            </div>

            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-purple/20 to-pink-600/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center h-full">
                <div className="text-5xl mb-4">🐙</div>
                <h3 className="card-title text-white mb-3 group-hover:text-purple transition-colors">GitHub</h3>
                <p className="text-gray-300 mb-6 text-sm">
                  Explore my work — infrastructure, pipelines, GitOps, and full architecture documentation.
                </p>
                <a
                  href="https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-purple hover:text-cyan transition-colors font-medium text-sm"
                >
                  View Repository
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                    />
                  </svg>
                </a>
              </div>
            </div>

            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-green-500/20 to-cyan/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card group-hover:scale-105 transition-all duration-300 text-center h-full">
                <div className="text-5xl mb-4">📅</div>
                <h3 className="card-title text-white mb-3 group-hover:text-green-400 transition-colors">
                  Book a Call
                </h3>
                <p className="text-gray-300 mb-6 text-sm">
                  {hasCalendly
                    ? 'Schedule a conversation about roles, platform work, or collaboration.'
                    : 'Prefer a call? Email me and we can arrange a time.'}
                </p>
                {hasCalendly ? (
                  <a
                    href="#book-call"
                    className="inline-flex items-center gap-2 text-green-400 hover:text-cyan transition-colors font-medium text-sm"
                  >
                    Pick a time
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M19 14l-7 7m0 0l-7-7m7 7V3"
                      />
                    </svg>
                  </a>
                ) : (
                  <a
                    href="mailto:olatunbosunkayode47@gmail.com"
                    className="inline-flex items-center gap-2 text-green-400 hover:text-cyan transition-colors font-medium text-sm"
                  >
                    Email to schedule
                  </a>
                )}
              </div>
            </div>
          </div>

          {hasCalendly && (
            <div id="book-call" className="mb-16 scroll-mt-24">
              <div className="text-center mb-8">
                <h3 className="text-2xl font-bold text-white mb-3">Schedule a conversation</h3>
                <p className="text-gray-400 max-w-2xl mx-auto">
                  Pick a time that works for you — no back-and-forth emails required.
                </p>
              </div>
              <div className="max-w-4xl mx-auto">
                <CalendlyEmbed />
              </div>
              <p className="text-center mt-4">
                <a
                  href={calendlyUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-cyan hover:text-purple transition-colors"
                >
                  Open in Calendly ↗
                </a>
              </p>
            </div>
          )}

          <div className="card text-center max-w-2xl mx-auto">
            <div className="flex items-center justify-center gap-3 mb-4">
              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse" />
              <span className="text-green-400 font-semibold">Open to opportunities</span>
            </div>
            <p className="text-gray-400 text-sm mb-2">Platform / DevOps Engineer · Nimbus Compute</p>
            <p className="text-gray-300 mb-6">
              Currently delivering platform work at Nimbus Compute — and actively exploring
              Platform, DevOps, and related cloud infrastructure roles where I can own delivery
              from code to production.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              {hasCalendly && (
                <a href="#book-call" className="btn-primary inline-block text-center">
                  Book a Call
                </a>
              )}
              <a
                href="https://www.linkedin.com/in/olatunbosun-ibiyinka-406a6b123/"
                target="_blank"
                rel="noopener noreferrer"
                className={`${hasCalendly ? 'btn-secondary' : 'btn-primary'} inline-block text-center`}
              >
                Connect on LinkedIn
              </a>
              <a
                href="/cv.pdf"
                download="Olatunbosun_Ibiyinka_Platform_DevOps_Engineer.pdf"
                className="btn-secondary inline-block text-center"
              >
                Download CV
              </a>
            </div>
          </div>

          <div className="text-center mt-16 pt-8 border-t border-cyan/20">
            <p className="text-gray-400 text-sm">
              React + Tailwind CSS · Docker · nginx · Automated CI/CD · Cloud-native deployment
            </p>
            <p className="text-gray-500 text-xs mt-2">© 2026 Olatunbosun Ibiyinka</p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Contact;
