# ✅ Production Deployment Checklist

Use this checklist to ensure your deployment meets production-grade standards.

## Pre-Deployment

### Infrastructure
- [ ] Terraform code reviewed and tested
- [ ] All variables configured in `terraform.tfvars`
- [ ] Remote state backend configured
- [ ] Resource naming follows conventions
- [ ] Tags applied to all resources
- [ ] Cost estimates reviewed

### Security
- [ ] Azure AD RBAC configured
- [ ] Key Vault access policies configured
- [ ] Network security groups configured
- [ ] Private endpoints configured (if required)
- [ ] Secrets stored in Key Vault (not in code)
- [ ] Workload Identity configured
- [ ] Pod Security Standards enabled
- [ ] Network policies defined

### Monitoring
- [ ] Log Analytics workspace created
- [ ] Diagnostic settings enabled
- [ ] Prometheus/Grafana configured (if using)
- [ ] Alert rules configured
- [ ] Dashboard created

## Deployment

### Infrastructure Deployment
- [ ] Terraform plan reviewed
- [ ] Infrastructure deployed successfully
- [ ] All resources created and verified
- [ ] AKS cluster accessible
- [ ] ACR accessible
- [ ] Key Vault accessible

### Kubernetes Setup
- [ ] kubectl configured
- [ ] Secret Store CSI driver installed
- [ ] Workload Identity webhook installed
- [ ] Ingress controller installed (if using)
- [ ] Metrics server installed (for HPA)

### Application Deployment
- [ ] Docker image built and pushed
- [ ] Image scanned for vulnerabilities
- [ ] Kubernetes manifests updated
- [ ] Secrets mounted correctly
- [ ] Deployment applied successfully
- [ ] Pods running and healthy
- [ ] Service accessible
- [ ] Health checks passing

### Post-Deployment Verification
- [ ] Application accessible via service IP
- [ ] All pods in Running state
- [ ] HPA functioning correctly
- [ ] Secrets accessible in pods
- [ ] Logs showing no errors
- [ ] Metrics being collected
- [ ] Alerts configured and tested

## Security Review

### Access Control
- [ ] RBAC configured correctly
- [ ] Service accounts have minimal permissions
- [ ] Key Vault access restricted
- [ ] Network policies enforced
- [ ] Pod Security Standards enforced

### Secrets Management
- [ ] No secrets in code or images
- [ ] All secrets in Key Vault
- [ ] Secret rotation policy defined
- [ ] Access logs enabled

### Network Security
- [ ] Network policies applied
- [ ] Ingress configured with TLS
- [ ] Firewall rules configured
- [ ] DDoS protection enabled (if applicable)

## Monitoring & Observability

### Metrics
- [ ] Application metrics collected
- [ ] Infrastructure metrics collected
- [ ] Custom metrics defined (if needed)
- [ ] Dashboards created

### Logging
- [ ] Application logs collected
- [ ] Infrastructure logs collected
- [ ] Log retention configured
- [ ] Log queries tested

### Alerting
- [ ] Critical alerts configured
- [ ] Warning alerts configured
- [ ] Alert channels configured
- [ ] Alert rules tested

## High Availability

### Application
- [ ] Multiple replicas deployed (min 2)
- [ ] Pod Disruption Budget configured
- [ ] Health checks configured
- [ ] Auto-scaling configured

### Infrastructure
- [ ] Multi-AZ deployment (if applicable)
- [ ] Backup strategy defined
- [ ] Disaster recovery plan documented
- [ ] Failover tested

## Performance

### Resource Management
- [ ] Resource requests defined
- [ ] Resource limits defined
- [ ] HPA thresholds configured
- [ ] Node pool sizing appropriate

### Optimization
- [ ] Image size optimized
- [ ] Caching configured
- [ ] CDN configured (if applicable)
- [ ] Database optimized (if applicable)

## Documentation

### Technical Documentation
- [ ] Architecture diagram updated
- [ ] Deployment guide complete
- [ ] Runbooks created
- [ ] Troubleshooting guide created

### Operational Documentation
- [ ] On-call procedures documented
- [ ] Escalation paths defined
- [ ] Contact information updated
- [ ] Change management process defined

## Compliance & Governance

### Policies
- [ ] Azure Policy assignments reviewed
- [ ] Compliance requirements met
- [ ] Audit logs enabled
- [ ] Retention policies configured

### Backup & Recovery
- [ ] Backup strategy implemented
- [ ] Recovery procedures tested
- [ ] RTO/RPO defined
- [ ] Backup retention configured

## Cost Optimization

### Resource Optimization
- [ ] Right-sized resources
- [ ] Reserved instances considered
- [ ] Unused resources removed
- [ ] Cost alerts configured

### Monitoring
- [ ] Cost tracking enabled
- [ ] Budget alerts configured
- [ ] Cost optimization recommendations reviewed

## Testing

### Functional Testing
- [ ] Application functionality verified
- [ ] Integration tests passed
- [ ] End-to-end tests passed
- [ ] Performance tests passed

### Security Testing
- [ ] Vulnerability scans passed
- [ ] Penetration testing completed (if required)
- [ ] Security policies verified
- [ ] Access controls tested

### Disaster Recovery Testing
- [ ] Backup restoration tested
- [ ] Failover tested
- [ ] Recovery procedures documented
- [ ] RTO/RPO validated

## Sign-Off

- [ ] Infrastructure reviewed by: ________________
- [ ] Security reviewed by: ________________
- [ ] Application reviewed by: ________________
- [ ] Operations reviewed by: ________________
- [ ] Approved for production: ________________

Date: _______________

---

**Note**: This checklist should be customized based on your organization's requirements and compliance needs.

