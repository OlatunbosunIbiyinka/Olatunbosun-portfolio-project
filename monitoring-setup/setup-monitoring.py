import os
import subprocess
import time

# =============================
# Configuration
# =============================
ALERTMANAGER_TEMPLATE = "alertmanager-template.yaml"
SECRET_NAME = "alertmanager-email-config"
NAMESPACE = "monitoring"
GMAIL_USER = "olatunbosunkayode47@gmail.com"
GMAIL_PASS = os.getenv("GMAIL_APP_PASSWORD")  # Read from environment variable

# =============================
# Helper functions
# =============================
def run_cmd(cmd):
    """Run a shell command and print output live."""
    print(f"\n$ {' '.join(cmd)}")
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        print(line, end="")
    process.wait()
    if process.returncode != 0:
        print(f"Command failed with exit code {process.returncode}")
    return process.returncode

# =============================
# Script logic
# =============================
print("Setting up Prometheus + Grafana + Alertmanager with Gmail alerting...")

if not GMAIL_PASS:
    print("\n ERROR: GMAIL_APP_PASSWORD environment variable not set.")
    print("Run this command first (replace with your Gmail App Password):")
    print('   export GMAIL_APP_PASSWORD="your_16_char_app_password_here"')
    exit(1)

# 1️⃣ Create namespace
run_cmd(["kubectl", "create", "namespace", NAMESPACE])

# 2️⃣ Add Helm repo
run_cmd(["helm", "repo", "add", "prometheus-community", "https://prometheus-community.github.io/helm-charts"])
run_cmd(["helm", "repo", "update"])

# 3️⃣ Create Alertmanager config dynamically from template
print("\n Generating alertmanager.yaml from template...")
with open(ALERTMANAGER_TEMPLATE, "r") as f:
    template = f.read()

alertmanager_config = template.replace("{{GMAIL_USER}}", GMAIL_USER).replace("{{GMAIL_PASS}}", GMAIL_PASS)

with open("alertmanager.yaml", "w") as f:
    f.write(alertmanager_config)

# 4️⃣ Create Kubernetes secret
run_cmd(["kubectl", "-n", NAMESPACE, "delete", "secret", SECRET_NAME, "--ignore-not-found=true"])
run_cmd([
    "kubectl", "-n", NAMESPACE, "create", "secret", "generic", SECRET_NAME,
    "--from-file=alertmanager.yaml"
])

# 5️⃣ Install Prometheus stack with LoadBalancer services
run_cmd([
    "helm", "upgrade", "--install", "my-kube-prometheus",
    "prometheus-community/kube-prometheus-stack",
    "--namespace", NAMESPACE,
    "--set", "grafana.service.type=LoadBalancer",
    "--set", "prometheus.service.type=LoadBalancer",
    "--set", "alertmanager.service.type=LoadBalancer",
    "--set", f"alertmanager.configSecret={SECRET_NAME}"
])

print("\n Deployment triggered! It may take a few minutes for all pods to start.")
print("Check status with:")
print(f"   kubectl -n {NAMESPACE} get pods\n")
print("To access Grafana:")
print("   kubectl -n monitoring get svc | grep grafana")
print("\nUse 'python setup-monitoring.py' again to redeploy safely.")
