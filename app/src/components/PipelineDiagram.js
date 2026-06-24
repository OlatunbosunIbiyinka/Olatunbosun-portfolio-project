import React from 'react';

const deliveryStages = [
  {
    title: 'Plan & Build',
    description: 'Code quality checks, automated tests, and infrastructure validation before anything ships.',
    items: ['Lint & unit tests', 'SonarCloud analysis', 'Terraform fmt / validate / Checkov'],
  },
  {
    title: 'Secure & Package',
    description: 'Every artifact scanned and versioned — no untested or vulnerable releases.',
    items: ['Container vulnerability scanning (Trivy)', 'Immutable image tags', 'Policy gates on infra'],
  },
  {
    title: 'Deploy & Reconcile',
    description: 'Automated, auditable delivery — Git as source of truth, cluster reconciles to desired state.',
    items: ['GitOps manifest updates', 'Argo CD sync', 'Rolling updates with health checks'],
  },
  {
    title: 'Operate & Improve',
    description: 'Systems you can see, trust, and recover — monitoring, smoke tests, and documented rollback.',
    items: ['Post-deploy verification', 'Monitoring & alerting', 'Git-based rollback'],
  },
];

const principles = [
  { title: 'Automate repetition', detail: 'Pipelines handle builds, scans, and deploys — engineers focus on value' },
  { title: 'Security by default', detail: 'Scanning and policy checks run before production, not after incidents' },
  { title: 'Everything in Git', detail: 'Infrastructure, manifests, and config — auditable and recoverable' },
  { title: 'Built to scale', detail: 'Cloud-native patterns that grow with your team and workload' },
];

const PipelineDiagram = () => {
  return (
    <section id="approach" className="section-padding bg-gradient-to-b from-transparent via-navy/30 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            How I <span className="gradient-text">Deliver</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            A modern delivery approach — quality and security upfront, automation through the middle,
            reliable operations at the end. The same patterns work across projects and environments.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          {deliveryStages.map((stage, index) => (
            <div key={stage.title} className="group relative" style={{ animationDelay: `${index * 150}ms` }}>
              <div className="absolute inset-0 bg-gradient-to-br from-cyan/10 to-purple/10 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
              <div className="relative card h-full border border-cyan/20 group-hover:scale-[1.02] transition-all duration-300">
                <div className="w-8 h-8 rounded-full bg-gradient-to-r from-cyan to-purple flex items-center justify-center text-white font-bold text-sm mb-4">
                  {index + 1}
                </div>
                <h3 className="text-lg font-bold text-white mb-2 group-hover:text-cyan transition-colors">
                  {stage.title}
                </h3>
                <p className="text-gray-400 text-sm mb-4 leading-relaxed">{stage.description}</p>
                <ul className="space-y-2">
                  {stage.items.map((item) => (
                    <li key={item} className="flex items-start gap-2 text-xs text-gray-300">
                      <div className="w-1.5 h-1.5 bg-cyan rounded-full mt-1.5 flex-shrink-0" />
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>

        <div className="card max-w-5xl mx-auto mb-12">
          <h3 className="text-2xl font-bold gradient-text mb-6 text-center">End-to-End Flow</h3>
          <div className="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-2 text-center">
            {['Code Change', 'CI Pipeline', 'Security Gates', 'Registry', 'GitOps', 'Production'].map(
              (step, i, arr) => (
                <React.Fragment key={step}>
                  <div className="px-4 py-3 bg-navy/60 border border-cyan/20 rounded-lg min-w-[110px]">
                    <span className="text-sm font-medium text-white">{step}</span>
                  </div>
                  {i < arr.length - 1 && (
                    <span className="text-cyan text-2xl hidden md:block" aria-hidden="true">
                      →
                    </span>
                  )}
                </React.Fragment>
              )
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 max-w-5xl mx-auto">
          {principles.map((item) => (
            <div key={item.title} className="card text-center">
              <h4 className="font-bold text-cyan mb-2">{item.title}</h4>
              <p className="text-sm text-gray-400">{item.detail}</p>
            </div>
          ))}
        </div>

        <div className="mt-12 card max-w-4xl mx-auto text-center">
          <h3 className="text-xl font-bold text-white mb-3">This Site Is the Proof</h3>
          <p className="text-gray-300 text-sm leading-relaxed">
            You&apos;re looking at the output of this approach — React app, Docker multi-stage build,
            automated CI/CD, vulnerability scanning, GitOps deployment on Kubernetes, and cloud
            infrastructure provisioned as code. I don&apos;t just talk about delivery pipelines; I run on one.
          </p>
        </div>
      </div>
    </section>
  );
};

export default PipelineDiagram;
