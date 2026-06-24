import React from 'react';

const projects = [
  {
    title: 'End-to-End Cloud Platform Portfolio',
    featured: true,
    description:
      'A complete demonstration of modern platform engineering — automated infrastructure, three CI/CD pipelines, containerised application delivery, GitOps deployment, security gates, and production-pattern operations. Proof that I can design, build, and run a full stack from code to cloud.',
    stack: [
      'Terraform',
      'Kubernetes / AKS',
      'GitHub Actions',
      'Argo CD',
      'Docker',
      'Trivy',
      'Checkov',
      'Azure',
    ],
    outcomes: [
      'Full delivery lifecycle automated — build, scan, deploy, verify',
      'Infrastructure as code with multi-environment readiness',
      'Security and quality gates embedded in every pipeline',
      'GitOps rollback, smoke tests, and operational runbooks documented',
    ],
    links: {
      github: 'https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project',
      docs: 'https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/blob/main/docs/ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md',
    },
    gradient: 'from-cyan/30 to-purple/30',
  },
  {
    title: 'Secure Cloud Network Architecture',
    featured: false,
    description:
      'Enterprise-grade Azure networking — isolated environments, private connectivity, controlled access, and security layers that support regulated and production workloads.',
    stack: ['Azure VNet', 'Bastion', 'Key Vault', 'Private Endpoints', 'NSG', 'NAT Gateway', 'RBAC'],
    outcomes: [
      'Zero-trust network design with minimal public exposure',
      'Least-privilege access and identity-based authentication',
      'Secure foundation for containers, registries, and secrets',
      'Compliance-ready network segmentation',
    ],
    links: {},
    gradient: 'from-purple/20 to-pink-600/20',
  },
  {
    title: 'DevSecOps CI/CD Pipeline',
    featured: false,
    description:
      'Automated build-and-deploy pipeline with infrastructure provisioning, container scanning, code quality analysis, and observability — security integrated at every stage.',
    stack: ['GitHub Actions', 'Terraform', 'Kubernetes', 'SonarCloud', 'Trivy', 'Helm'],
    outcomes: [
      'Automated infrastructure and application delivery',
      'Vulnerability and quality gates before release',
      'Repeatable, auditable deployment process',
      'Monitoring and alerting wired into the stack',
    ],
    links: {},
    gradient: 'from-cyan/20 to-purple/20',
  },
];

const Projects = () => {
  return (
    <section id="projects" className="section-padding bg-gradient-to-b from-navy/50 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Featured <span className="gradient-text">Projects</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Platform engineering work and reference implementations — infrastructure,
            automation, security, and full-stack delivery.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {projects.map((project, index) => (
            <div
              key={project.title}
              className={`group relative ${project.featured ? 'lg:col-span-2' : ''}`}
              style={{ animationDelay: `${index * 150}ms` }}
            >
              <div
                className={`absolute inset-0 bg-gradient-to-br ${project.gradient} rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl`}
              />

              <div
                className={`relative card group-hover:scale-[1.01] transition-all duration-300 h-full ${
                  project.featured ? 'lg:p-8' : ''
                }`}
              >
                <div className={`flex flex-col h-full ${project.featured ? 'lg:flex-row lg:gap-10' : ''}`}>
                  <div className={project.featured ? 'lg:flex-1' : ''}>
                    {project.featured && (
                      <span className="inline-block badge mb-4 text-purple border-purple/40">
                        Flagship — Full Stack Delivery
                      </span>
                    )}

                    <h3 className="card-title text-white mb-3 group-hover:text-cyan transition-colors duration-300">
                      {project.title}
                    </h3>
                    <p className="text-gray-300 leading-relaxed mb-6">{project.description}</p>

                    <div className="mb-6">
                      <h4 className="text-cyan text-sm font-semibold mb-3 uppercase tracking-wide">
                        Technology Stack
                      </h4>
                      <div className="flex flex-wrap gap-2">
                        {project.stack.map((tech) => (
                          <span key={tech} className="badge">
                            {tech}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className={project.featured ? 'lg:flex-1' : 'flex-grow'}>
                    <h4 className="text-purple text-sm font-semibold mb-3 uppercase tracking-wide">
                      Business & Technical Outcomes
                    </h4>
                    <ul className="space-y-2 mb-6">
                      {project.outcomes.map((outcome) => (
                        <li key={outcome} className="flex items-start space-x-2 text-gray-300 text-sm">
                          <div className="w-1.5 h-1.5 bg-gradient-to-r from-cyan to-purple rounded-full mt-2 flex-shrink-0" />
                          <span>{outcome}</span>
                        </li>
                      ))}
                    </ul>

                    {(project.links.github || project.links.docs) && (
                      <div className="flex flex-wrap gap-4 pt-4 border-t border-cyan/20">
                        {project.links.github && (
                          <a
                            href={project.links.github}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-cyan hover:text-purple transition-colors font-medium flex items-center gap-2"
                          >
                            View on GitHub
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                              />
                            </svg>
                          </a>
                        )}
                        {project.links.docs && (
                          <a
                            href={project.links.docs}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-purple hover:text-cyan transition-colors font-medium flex items-center gap-2"
                          >
                            Architecture Docs
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M9 5l7 7-7 7"
                              />
                            </svg>
                          </a>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="text-center mt-16">
          <p className="text-gray-300 mb-6">
            Need someone who can own infrastructure, pipelines, and production delivery?
          </p>
          <a href="#contact" className="btn-primary inline-block">
            Let&apos;s Talk
          </a>
        </div>
      </div>
    </section>
  );
};

export default Projects;
