export const suggestedQuestions = [
  'What roles are you open to?',
  'What roles can I fill?',
  'Tell me about your platform project',
  'What is your experience at Nimbus?',
  'How can I contact you?',
];

const projectResponse =
  'His flagship project is an end-to-end cloud platform portfolio on private AKS: Terraform infrastructure, three GitHub Actions pipelines, GitOps with Argo CD, Trivy/Checkov/SonarCloud gates, and full architecture documentation. Explore it on GitHub or the Architecture section on this site.';

const aboutResponse =
  'Olatunbosun Ibiyinka is a Platform / DevOps Engineer at Nimbus Compute. He helps teams ship software faster and safer through cloud infrastructure, CI/CD automation, container platforms, and DevSecOps — plus a personal portfolio that proves full-stack platform delivery depth.';

const rolesCanFillResponse =
  'Strong fits: Platform Engineer, DevOps Engineer, Cloud Platform Engineer, Azure DevOps Engineer, Kubernetes Platform Engineer, DevSecOps Engineer, CI/CD / Release Engineer, and Cloud Infrastructure Engineer. Also well suited to SRE (platform-focused), internal developer platform work, and consulting-style platform delivery — based on his Nimbus experience and full-stack Azure/Kubernetes portfolio.';

const rolesOpenResponse =
  'Olatunbosun is a Platform / DevOps Engineer currently at Nimbus Compute and actively open to Platform, DevOps, and related cloud infrastructure roles — where he can own delivery from code to production.';

// Checked first — most specific phrases win
export const phraseIntents = [
  {
    phrases: [
      'tell me about your platform project',
      'about your platform project',
      'about the platform project',
      'platform project',
      'this platform project',
      'flagship project',
      'end to end platform',
      'portfolio project',
      'what is this project',
      'what is this portfolio',
    ],
    response: projectResponse,
  },
  {
    phrases: [
      'tell me about yourself',
      'about yourself',
      'who are you',
      'introduce yourself',
      'tell me about you',
    ],
    response: aboutResponse,
  },
  {
    phrases: ['experience at nimbus', 'work at nimbus', 'what is your experience at nimbus'],
    response:
      'At Nimbus Compute he delivers platform projects, client consultation, mentors junior engineers, and executes subcontracted platform work on Azure/Kubernetes — covering Terraform, CI/CD, monitoring, and DevSecOps.',
  },
  {
    phrases: [
      'what roles can i fill',
      'what roles can you fill',
      'roles can i fill',
      'roles can you fill',
      'what kind of roles',
      'what jobs can you do',
      'what positions',
    ],
    response: rolesCanFillResponse,
  },
  {
    phrases: [
      'roles are you open',
      'what roles are you open',
      'open to roles',
      'open to opportunities',
      'job hunting',
      'looking for work',
      'currently hiring',
    ],
    response: rolesOpenResponse,
  },
  {
    phrases: ['how can i contact', 'how to contact', 'get in touch', 'reach you'],
    response:
      'Best ways to connect: email olatunbosunkayode47@gmail.com, LinkedIn (link in Contact), download the CV from the Hero or Contact section, or scroll to Contact for GitHub and scheduling options.',
  },
];

export const intents = [
  {
    keywords: ['open to', 'opportunity', 'opportunities', 'job hunting', 'looking for work', 'available'],
    response: rolesOpenResponse,
  },
  {
    keywords: ['fill', 'qualified', 'suitable', 'fit for'],
    response: rolesCanFillResponse,
  },
  {
    keywords: ['role', 'roles', 'job', 'hiring', 'available', 'looking'],
    response: rolesOpenResponse,
  },
  {
    keywords: ['nimbus', 'employer', 'consultation', 'mentor', 'client', 'subcontract'],
    response:
      'At Nimbus Compute he delivers platform projects, client consultation, mentors junior engineers, and executes subcontracted platform work on Azure/Kubernetes — covering Terraform, CI/CD, monitoring, and DevSecOps.',
  },
  {
    keywords: ['project', 'portfolio', 'github', 'flagship', 'demonstration', 'architecture diagram', 'this site'],
    response: projectResponse,
  },
  {
    keywords: ['terraform', 'infrastructure', 'iac', 'azure', 'vnet', 'network', 'aks', 'kubernetes', 'k8s', 'gitops', 'argocd', 'argo'],
    response:
      'Core stack: Terraform on Azure (VNet, private AKS, ACR, Key Vault, Bastion), Kubernetes with GitOps via Argo CD, Cilium networking, and infrastructure validated in CI with Checkov. The architecture diagram on this site shows the full flow.',
  },
  {
    keywords: ['cicd', 'ci/cd', 'pipeline', 'devsecops', 'trivy', 'sonar', 'checkov', 'security', 'scan'],
    response:
      'He runs three path-filtered pipelines: quality checks, build/push with Trivy scanning on a self-hosted runner, and Terraform plan-only with OIDC. Security and quality gates run before anything reaches the cluster.',
  },
  {
    keywords: ['skill', 'skills', 'stack', 'tech', 'technology', 'tools'],
    response:
      'Key skills: Terraform, Azure, Kubernetes/AKS, GitHub Actions, Docker, Argo CD, Helm, Trivy, Checkov, SonarCloud, Prometheus/Grafana, and production-style operations (Bastion access, runbooks, smoke tests). See the Skills section for the full breakdown.',
  },
  {
    keywords: ['contact', 'email', 'linkedin', 'reach', 'connect', 'cv', 'resume', 'download'],
    response:
      'Best ways to connect: email olatunbosunkayode47@gmail.com, LinkedIn (link in Contact), download the CV from the Hero or Contact section, or scroll to Contact for GitHub and scheduling options.',
  },
  {
    keywords: ['meet', 'call', 'schedule', 'calendly', 'interview'],
    response:
      'Head to the Contact section to email, connect on LinkedIn, or book a call if Calendly is enabled. He is actively exploring new Platform and DevOps opportunities.',
  },
  {
    keywords: ['who is', 'background', 'olatunbosun', 'ibiyinka'],
    response: aboutResponse,
  },
];

export const fallbackResponse =
  'I can help with questions about Olatunbosun\'s roles, experience at Nimbus, tech stack, platform project, and how to get in touch. Try one of the suggested prompts below.';
