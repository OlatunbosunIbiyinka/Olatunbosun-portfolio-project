import React from 'react';

const valueProps = [
  {
    title: 'Ship Faster, With Confidence',
    description:
      'Automated CI/CD pipelines that build, test, scan, and deploy — reducing manual steps and catching issues before production.',
    icon: '🚀',
  },
  {
    title: 'Infrastructure You Can Rebuild',
    description:
      'Everything declared as code — version-controlled, reviewable, and reproducible across dev, staging, and production.',
    icon: '🏗️',
  },
  {
    title: 'Security Built In',
    description:
      'DevSecOps from day one — vulnerability scanning, policy checks, least-privilege access, and secrets managed properly.',
    icon: '🛡️',
  },
  {
    title: 'Platforms That Scale',
    description:
      'Cloud-native architectures on Kubernetes and Azure — designed for growth, resilience, and operational clarity.',
    icon: '📈',
  },
  {
    title: 'Observable Systems',
    description:
      'Monitoring, logging, and alerting so teams see problems early — not when customers report them.',
    icon: '📊',
  },
  {
    title: 'Reliable Delivery',
    description:
      'GitOps, immutable artifacts, and rollback-ready workflows — predictable releases your business can depend on.',
    icon: '✅',
  },
];

const Value = () => {
  return (
    <section id="value" className="section-padding bg-gradient-to-b from-navy/50 via-navy/30 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Value I <span className="gradient-text">Deliver</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            I help teams and organisations modernise how they build, deploy, and operate software —
            with automation, security, and reliability at the centre.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {valueProps.map((item, index) => (
            <div key={item.title} className="group relative" style={{ animationDelay: `${index * 100}ms` }}>
              <div className="absolute inset-0 bg-gradient-to-br from-cyan/10 to-purple/10 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card h-full group-hover:scale-[1.02] transition-all duration-300">
                <div className="text-4xl mb-4">{item.icon}</div>
                <h3 className="text-xl font-bold text-white mb-3 group-hover:text-cyan transition-colors">
                  {item.title}
                </h3>
                <p className="text-gray-300 text-sm leading-relaxed">{item.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Value;
