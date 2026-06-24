import React from 'react';

const skillCategories = [
  {
    title: 'Cloud & Infrastructure',
    skills: ['Terraform', 'Azure', 'AWS', 'VNet Design', 'IaC Modules', 'Multi-Environment'],
    color: 'from-cyan/30 to-blue-600/20',
  },
  {
    title: 'CI/CD & Automation',
    skills: ['GitHub Actions', 'Docker', 'Build Pipelines', 'GitOps', 'Argo CD', 'Helm'],
    color: 'from-purple/30 to-pink-600/20',
  },
  {
    title: 'Containers & Orchestration',
    skills: ['Kubernetes', 'AKS', 'Node Pools', 'HPA / PDB', 'Service Mesh Ready', 'Rolling Deploys'],
    color: 'from-cyan/30 to-purple/20',
  },
  {
    title: 'Security & DevSecOps',
    skills: ['Trivy', 'Checkov', 'SonarCloud', 'OIDC / RBAC', 'Key Vault', 'Network Policies'],
    color: 'from-blue-600/30 to-cyan/20',
  },
  {
    title: 'Monitoring & Reliability',
    skills: ['Prometheus', 'Grafana', 'Azure Monitor', 'Log Analytics', 'Health Checks', 'Smoke Tests'],
    color: 'from-purple/30 to-cyan/20',
  },
  {
    title: 'Operations & Delivery',
    skills: ['Bastion Access', 'Runbooks', 'Rollback Strategy', 'Immutable Artifacts', 'Team Collaboration'],
    color: 'from-cyan/30 to-purple/30',
  },
];

const Skills = () => {
  return (
    <section id="skills" className="section-padding bg-gradient-to-b from-navy/50 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Technical <span className="gradient-text">Skills</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            A broad toolkit for modern software delivery — cloud foundations, automation,
            security, and operations that keep systems running in production.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {skillCategories.map((category, index) => (
            <div key={category.title} className="group relative" style={{ animationDelay: `${index * 100}ms` }}>
              <div
                className={`absolute inset-0 bg-gradient-to-br ${category.color} rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl`}
              />
              <div className="relative card h-full group-hover:scale-[1.02] transition-all duration-300">
                <h3 className="card-title text-white mb-4 group-hover:text-cyan transition-colors">
                  {category.title}
                </h3>
                <div className="flex flex-wrap gap-2">
                  {category.skills.map((skill) => (
                    <span key={skill} className="badge">
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Skills;
