import React from 'react';

const About = () => {
  const techStack = [
    { name: 'Terraform', category: 'Infrastructure' },
    { name: 'Kubernetes', category: 'Orchestration' },
    { name: 'GitHub Actions', category: 'CI/CD' },
    { name: 'Prometheus', category: 'Monitoring' },
    { name: 'Grafana', category: 'Visualization' },
    { name: 'Azure', category: 'Cloud' },
    { name: 'AWS', category: 'Cloud' },
  ];

  return (
    <section id="about" className="section-padding bg-gradient-to-b from-transparent to-navy/50">
      <div className="container">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {/* Profile Image */}
          <div className="order-2 lg:order-1 flex justify-center lg:justify-start">
            <div className="relative group">
              <div className="absolute inset-0 bg-gradient-to-br from-cyan/20 to-purple/20 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"></div>
              <div className="relative">
                <img 
                  src="/profile.jpg" 
                  alt="Olatunbosun Ibiyinka" 
                  className="w-80 h-80 object-cover rounded-2xl border-2 border-cyan/30 group-hover:border-cyan/60 transition-all duration-300 shadow-lg hover:shadow-cyan/25"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-navy/20 to-transparent rounded-2xl"></div>
              </div>
            </div>
          </div>
          
          {/* Text Content */}
          <div className="order-1 lg:order-2">
            <h2 className="section-title mb-2">
              About <span className="gradient-text">Me</span>
            </h2>
            <h3 className="text-2xl font-semibold text-cyan mb-6">Olatunbosun Ibiyinka</h3>
            <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mb-8"></div>
            
            <div className="space-y-6 text-lg text-gray-300 leading-relaxed">
              <p>
                I'm an emerging DevOps engineer passionate about building secure, scalable 
                cloud infrastructure. Through hands-on projects and collaborative learning, 
                I've developed expertise in Azure cloud services, container orchestration, 
                and DevSecOps practices.
              </p>
              
              <p>
                My journey focuses on infrastructure-as-code principles, automated CI/CD 
                pipelines, and comprehensive monitoring solutions. I believe in learning 
                by doing, tackling real-world challenges, and collaborating with fellow 
                engineers to build production-grade systems.
              </p>
              
              <p>
                From secure multi-VNet architectures to end-to-end DevSecOps pipelines, 
                I'm committed to continuous learning and applying best practices in 
                cloud-native technologies.
              </p>
            </div>
          </div>
          
          {/* Tech Stack */}
          <div>
            <h3 className="text-2xl font-bold mb-8 gradient-text">Core Technologies</h3>
            
            <div className="grid grid-cols-2 gap-4">
              {techStack.map((tech, index) => (
                <div 
                  key={tech.name}
                  className="group relative"
                  style={{animationDelay: `${index * 100}ms`}}
                >
                  <div className="card group-hover:scale-105 transition-all duration-300 text-center">
                    <div className="mb-2">
                      <span className="text-sm text-cyan/70 uppercase tracking-wide font-medium">
                        {tech.category}
                      </span>
                    </div>
                    <h4 className="text-white font-semibold text-lg">
                      {tech.name}
                    </h4>
                  </div>
                  
                  {/* Hover Glow Effect */}
                  <div className="absolute inset-0 bg-gradient-to-r from-cyan/20 to-purple/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 -z-10 blur-sm"></div>
                </div>
              ))}
            </div>
            
            {/* Achievement Highlights */}
            <div className="mt-12 space-y-4">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-cyan rounded-full"></div>
                <span className="text-gray-300">Nimbus Compute DevOps Apprentice</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-purple rounded-full"></div>
                <span className="text-gray-300">End-to-end DevSecOps pipeline implementation</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-cyan rounded-full"></div>
                <span className="text-gray-300">Collaborative DevOps project experience</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-purple rounded-full"></div>
                <span className="text-gray-300">Azure cloud infrastructure specialist</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default About;
