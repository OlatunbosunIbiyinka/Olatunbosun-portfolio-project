import React from 'react';

const PipelineDiagram = () => {
  const pipelineSteps = [
    {
      id: 'cicd',
      title: 'CI/CD Pipeline',
      description: 'Automated testing, building, and deployment workflows',
      icon: '🔄',
      details: ['GitHub Actions', 'Automated Testing', 'Security Scanning', 'Artifact Generation'],
      position: 'top-left'
    },
    {
      id: 'iac',
      title: 'Infrastructure as Code',
      description: 'Declarative infrastructure provisioning and management',
      icon: '🏗️',
      details: ['Terraform', 'CloudFormation', 'Version Control', 'State Management'],
      position: 'top-right'
    },
    {
      id: 'kubernetes',
      title: 'Kubernetes',
      description: 'Container orchestration and application deployment',
      icon: '⚓',
      details: ['Pod Management', 'Service Discovery', 'Auto-scaling', 'Load Balancing'],
      position: 'bottom-left'
    },
    {
      id: 'monitoring',
      title: 'Monitoring & Observability',
      description: 'Real-time metrics, logging, and alerting systems',
      icon: '📊',
      details: ['Prometheus', 'Grafana', 'Log Aggregation', 'Alert Management'],
      position: 'bottom-right'
    }
  ];

  const connections = [
    { from: 'cicd', to: 'iac', type: 'horizontal' },
    { from: 'cicd', to: 'kubernetes', type: 'vertical' },
    { from: 'iac', to: 'monitoring', type: 'vertical' },
    { from: 'kubernetes', to: 'monitoring', type: 'horizontal' }
  ];

  return (
    <section id="pipeline" className="section-padding bg-gradient-to-b from-transparent via-navy/30 to-transparent">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="section-title mb-6">
            Delivery <span className="gradient-text">Pipeline</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8"></div>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            A comprehensive view of how I architect modern DevOps pipelines for 
            reliable, scalable, and observable application delivery.
          </p>
        </div>

        {/* Pipeline Diagram */}
        <div className="relative max-w-6xl mx-auto">
          {/* Connection Lines */}
          <div className="absolute inset-0 pointer-events-none">
            {/* Horizontal connections */}
            <div className="absolute top-1/2 left-1/4 right-1/4 h-0.5 bg-gradient-to-r from-cyan to-purple transform -translate-y-1/2 hidden lg:block">
              <div className="absolute right-0 top-1/2 transform translate-x-1 -translate-y-1/2">
                <div className="w-0 h-0 border-l-4 border-l-purple border-t-2 border-b-2 border-t-transparent border-b-transparent"></div>
              </div>
            </div>
            
            <div className="absolute bottom-1/4 left-1/4 right-1/4 h-0.5 bg-gradient-to-r from-cyan to-purple hidden lg:block">
              <div className="absolute right-0 top-1/2 transform translate-x-1 -translate-y-1/2">
                <div className="w-0 h-0 border-l-4 border-l-purple border-t-2 border-b-2 border-t-transparent border-b-transparent"></div>
              </div>
            </div>

            {/* Vertical connections */}
            <div className="absolute left-1/4 top-1/4 bottom-1/4 w-0.5 bg-gradient-to-b from-cyan to-purple transform -translate-x-1/2 hidden lg:block">
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 translate-y-1">
                <div className="w-0 h-0 border-t-4 border-t-purple border-l-2 border-r-2 border-l-transparent border-r-transparent"></div>
              </div>
            </div>
            
            <div className="absolute right-1/4 top-1/4 bottom-1/4 w-0.5 bg-gradient-to-b from-cyan to-purple transform translate-x-1/2 hidden lg:block">
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 translate-y-1">
                <div className="w-0 h-0 border-t-4 border-t-purple border-l-2 border-r-2 border-l-transparent border-r-transparent"></div>
              </div>
            </div>
          </div>

          {/* Pipeline Steps */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-16">
            {pipelineSteps.map((step, index) => (
              <div 
                key={step.id}
                className="group relative"
                style={{animationDelay: `${index * 200}ms`}}
              >
                {/* Glow Effect */}
                <div className="absolute inset-0 bg-gradient-to-br from-cyan/20 to-purple/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"></div>
                
                {/* Card */}
                <div className="relative card group-hover:scale-105 transition-all duration-300 text-center">
                  {/* Icon */}
                  <div className="text-6xl mb-4 filter grayscale group-hover:grayscale-0 transition-all duration-300">
                    {step.icon}
                  </div>
                  
                  {/* Title */}
                  <h3 className="card-title text-white mb-3 group-hover:text-cyan transition-colors duration-300">
                    {step.title}
                  </h3>
                  
                  {/* Description */}
                  <p className="text-gray-300 mb-6 leading-relaxed">
                    {step.description}
                  </p>
                  
                  {/* Details */}
                  <div className="space-y-2">
                    {step.details.map((detail, idx) => (
                      <div key={idx} className="flex items-center justify-center space-x-2 text-sm text-gray-400">
                        <div className="w-1.5 h-1.5 bg-gradient-to-r from-cyan to-purple rounded-full"></div>
                        <span>{detail}</span>
                      </div>
                    ))}
                  </div>
                  
                  {/* Step Number */}
                  <div className="absolute -top-3 -right-3 w-8 h-8 bg-gradient-to-r from-cyan to-purple rounded-full flex items-center justify-center text-white font-bold text-sm">
                    {index + 1}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Flow Description */}
          <div className="mt-16 text-center">
            <div className="card max-w-4xl mx-auto">
              <h3 className="text-2xl font-bold gradient-text mb-4">End-to-End Automation</h3>
              <p className="text-gray-300 leading-relaxed">
                This integrated pipeline ensures that code changes flow seamlessly from development 
                through to production, with infrastructure provisioned as code, applications deployed 
                on Kubernetes, and comprehensive monitoring providing visibility into every aspect 
                of the system's health and performance.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default PipelineDiagram;
