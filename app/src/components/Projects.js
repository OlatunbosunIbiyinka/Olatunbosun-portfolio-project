import React from 'react';

const Projects = () => {
  const projects = [
    {
      title: 'NimbusShop',
      description: 'End-to-end collaborative DevOps project deploying an e-commerce application on Kubernetes with comprehensive monitoring and security scanning.',
      stack: ['Terraform', 'Azure AKS', 'Prometheus', 'Grafana', 'SonarCloud', 'Trivy'],
      outcomes: [
        'Production-grade Kubernetes deployment',
        'Integrated DevSecOps security scanning',
        'Real-time monitoring and visualization',
        'Collaborative DevOps workflow implementation'
      ],
      gradient: 'from-cyan/20 to-blue-600/20'
    },
    {
      title: 'Secure Azure Infrastructure',
      description: 'Production-grade, secure multi-network cloud environment with zero-trust architecture and private endpoints.',
      stack: ['Azure VNet', 'Azure Bastion', 'Key Vault', 'NSG', 'Private Endpoints', 'RBAC'],
      outcomes: [
        'Two isolated VNets with private VMs',
        'Zero public IP exposure',
        'Least privilege access implementation',
        'Complete network security with NSGs'
      ],
      gradient: 'from-purple/20 to-pink-600/20'
    },
    {
      title: 'End-to-End DevSecOps Pipeline',
      description: 'Comprehensive CI/CD architecture with automated security scanning, infrastructure provisioning, and monitoring.',
      stack: ['GitHub Actions', 'Terraform', 'Azure AKS', 'SonarCloud', 'Trivy', 'Helm'],
      outcomes: [
        'Automated infrastructure provisioning',
        'Security-first CI/CD pipeline',
        'Container vulnerability scanning',
        'Comprehensive observability stack'
      ],
      gradient: 'from-cyan/20 to-purple/20'
    }
  ];

  return (
    <section id="projects" className="section-padding bg-gradient-to-b from-navy/50 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Featured <span className="gradient-text">Projects</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8"></div>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Explore my latest infrastructure and DevOps implementations that power 
            mission-critical applications at scale.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {projects.map((project, index) => (
            <div 
              key={project.title}
              className="group relative"
              style={{animationDelay: `${index * 150}ms`}}
            >
              {/* Background Glow */}
              <div className={`absolute inset-0 bg-gradient-to-br ${project.gradient} rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl`}></div>
              
              {/* Card */}
              <div className="relative card group-hover:scale-[1.02] transition-all duration-300 h-full">
                <div className="flex flex-col h-full">
                  {/* Header */}
                  <div className="mb-6">
                    <h3 className="card-title text-white mb-3 group-hover:text-cyan transition-colors duration-300">
                      {project.title}
                    </h3>
                    <p className="text-gray-300 leading-relaxed">
                      {project.description}
                    </p>
                  </div>

                  {/* Tech Stack */}
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

                  {/* Outcomes */}
                  <div className="flex-grow">
                    <h4 className="text-purple text-sm font-semibold mb-3 uppercase tracking-wide">
                      Key Outcomes
                    </h4>
                    <ul className="space-y-2">
                      {project.outcomes.map((outcome, idx) => (
                        <li key={idx} className="flex items-start space-x-2 text-gray-300 text-sm">
                          <div className="w-1.5 h-1.5 bg-gradient-to-r from-cyan to-purple rounded-full mt-2 flex-shrink-0"></div>
                          <span>{outcome}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Action Button */}
                  <div className="mt-6 pt-4 border-t border-cyan/20">
                    <button className="text-cyan hover:text-purple transition-colors duration-300 font-medium flex items-center space-x-2 group">
                      <span>View Details</span>
                      <svg className="w-4 h-4 transform group-hover:translate-x-1 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Call to Action */}
        <div className="text-center mt-16">
          <p className="text-gray-300 mb-6">
            Want to see more of my work or discuss a project?
          </p>
          <button className="btn-primary">
            Let's Talk
          </button>
        </div>
      </div>
    </section>
  );
};

export default Projects;
