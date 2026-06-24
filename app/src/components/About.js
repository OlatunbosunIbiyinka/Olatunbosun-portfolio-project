import React from 'react';

const experience = {
  company: 'Nimbus Compute',
  role: 'Platform Engineer',
  period: 'Present',
  summary:
    'Platform engineer at Nimbus Compute — delivering client-facing platform work across Azure and Kubernetes, from infrastructure and pipelines through to security, observability, and operational standards.',
  responsibilities: [
    {
      title: 'Platform delivery',
      detail:
        'Lead and contribute to platform engineering projects — Terraform, CI/CD automation, container orchestration, monitoring, and DevSecOps integration on the Nimbus stack.',
    },
    {
      title: 'Client consultation',
      detail:
        'Advise clients on cloud infrastructure, delivery pipelines, and platform design — translating requirements into secure, repeatable engineering approaches.',
    },
    {
      title: 'Engineering mentorship',
      detail:
        'Mentor junior engineers on infrastructure as code, pipeline design, Kubernetes operations, and platform best practices.',
    },
    {
      title: 'Subcontracted engagements',
      detail:
        'Deliver subcontracted platform and delivery work on behalf of Nimbus Compute — end-to-end execution aligned with Nimbus engineering standards.',
    },
  ],
};

const capabilities = [
  'Design and automate CI/CD pipelines that shorten release cycles without sacrificing control',
  'Provision cloud infrastructure as code — repeatable, auditable, and environment-ready',
  'Deploy and operate containerised workloads on Kubernetes to production standard',
  'Embed vulnerability scanning and policy gates throughout the delivery workflow',
  'Establish monitoring and alerting so issues surface before they reach users',
  'Consult with teams and mentor engineers on platform design and operational readiness',
];

const About = () => {
  return (
    <section id="about" className="section-padding bg-gradient-to-b from-transparent to-navy/50">
      <div className="container max-w-4xl">
        <h2 className="section-title mb-2">
          About <span className="gradient-text">Me</span>
        </h2>
        <p className="text-xl text-cyan font-medium mb-2">Olatunbosun Ibiyinka</p>
        <p className="text-gray-400 mb-8">
          {experience.role} · {experience.company}
        </p>
        <div className="w-16 h-1 bg-gradient-to-r from-cyan to-purple mb-10" />

        <div className="space-y-6 text-lg text-gray-300 leading-relaxed mb-14">
          <p>
            I&apos;m a Platform Engineer at Nimbus Compute, where I work on client projects,
            technical consultation, and the standards that underpin how platforms are built and
            operated in the cloud.
          </p>
          <p>
            My day-to-day spans infrastructure as code, pipeline automation, Kubernetes delivery,
            and DevSecOps — alongside mentoring junior engineers and executing subcontracted
            engagements on behalf of Nimbus. I also maintain a personal platform portfolio that
            demonstrates the same engineering patterns at full stack depth.
          </p>
        </div>

        <div className="mb-14">
          <h3 className="text-2xl font-bold text-white mb-6">Current Role</h3>

          <div className="card border-cyan/30 p-6 sm:p-8">
            <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
              <div>
                <p className="text-sm text-cyan font-medium uppercase tracking-wide mb-1">
                  {experience.company}
                </p>
                <p className="text-xl font-semibold text-white">{experience.role}</p>
              </div>
              <span className="inline-flex items-center gap-2 badge text-green-400 border-green-400/40">
                <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                {experience.period}
              </span>
            </div>

            <p className="text-gray-300 leading-relaxed mb-8">{experience.summary}</p>

            <div className="space-y-5">
              {experience.responsibilities.map((item) => (
                <div key={item.title}>
                  <p className="text-white font-semibold mb-1">{item.title}</p>
                  <p className="text-gray-300 text-base leading-relaxed">{item.detail}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div>
          <h3 className="text-2xl font-bold text-white mb-6">What I Do</h3>
          <ul className="space-y-4">
            {capabilities.map((item) => (
              <li key={item} className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gradient-to-r from-cyan to-purple rounded-full mt-2.5 flex-shrink-0" />
                <span className="text-gray-300">{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
};

export default About;
