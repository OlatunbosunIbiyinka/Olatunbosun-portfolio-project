import React from 'react';

const Architecture = () => {
  return (
    <section id="architecture" className="section-padding bg-gradient-to-b from-transparent via-navy/20 to-transparent">
      <div className="container">
        <div className="text-center mb-12">
          <h2 className="section-title mb-6">
            Platform <span className="gradient-text">Architecture</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mx-auto mb-8" />
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            End-to-end delivery on Azure — automated pipelines, infrastructure as code, private
            cloud foundations, and GitOps-controlled runtime. This is the platform this site runs on.
          </p>
        </div>

        <div className="group relative max-w-6xl mx-auto">
          <div className="absolute inset-0 bg-gradient-to-br from-cyan/10 to-purple/10 rounded-2xl opacity-60 blur-2xl" />
          <div className="relative card p-3 sm:p-4 lg:p-6 border-cyan/30">
            <img
              src="/architecture.png"
              alt="Platform architecture diagram showing GitHub CI/CD, Terraform provisioning, private Azure AKS, Argo CD GitOps, and end-user traffic flow"
              className="w-full h-auto rounded-lg border border-cyan/10"
              loading="lazy"
            />
          </div>
        </div>

        <p className="text-center text-gray-400 text-sm mt-8 max-w-2xl mx-auto">
          Three path-filtered pipelines · OIDC-authenticated CI · Self-hosted runner for private registry
          · Terraform plan/apply separation · Argo CD in-cluster reconciliation
        </p>
      </div>
    </section>
  );
};

export default Architecture;
