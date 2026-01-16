# IDP Transformation Roadmap: K3s Homelab

**Objective**: Transform the current bare-metal K3s cluster (optimized for mining) into a production-grade Internal Developer Platform (IDP) with full GitOps, Observability, and Security standards.

## 🧱 Phase 0: gVisor & Infrastructure Foundations (Pre-GitOps)
**Goal**: Enable secure multi-tenancy for Akash workloads and fix infrastructure ownership.
- [ ] **Containerd Ownership Refactor**: Move `config.toml.tmpl` management from `roles/nvidia_gpu` to `roles/k3s_server` (Cluster-owned, not Vendor-owned).
- [ ] **gVisor Role**: Create Ansible role to install `runsc` and `containerd-shim-runsc-v1`.
- [ ] **Unified Config**: Update `config.toml.tmpl` to support both `nvidia` (runc v2) and `gvisor` (runsc/nvproxy) runtimes in a single unified template.
- [ ] **Driver Validation**: Implement "Driver Version Lock" check in Ansible to ensure NVIDIA driver matches `runsc` compatibility.
- [ ] **RuntimeClasses**: Deploy `gvisor` and `gvisor-gpu` classes (via Ansible initially, then GitOps).

## 🏗️ Phase 1: GitOps Foundation (Critical)
**Goal**: Switch from manual/Ansible deploys to declarative GitOps.
- [ ] **ArgoCD**: Deploy via Ansible (Helm chart).
- [ ] **App Structure**: Create `AppProjects` (cicd, events, observability, policies, security, production).
- [ ] **Migration**: Move existing manifests to `k8s/production` and `k8s/infrastructure`.
- [ ] **ApplicationSet**: Implement for auto-syncing production stack.
- [ ] **Miners**: Manage miner deployments via ArgoCD (Must use default runtime, NO gVisor).

## 👁️ Phase 2: Core Observability & Priority
**Goal**: Metrics visibility and workload prioritization.
- [ ] **Prometheus Stack**: Deploy `kube-prometheus-stack`.
- [ ] **Alertmanager**: Configure "Deadman Switch" with Healthchecks.io.
- [ ] **ServiceMonitors**: Monitor ArgoCD, Cilium/Hubble, GPU (dcgm), Miners.
- [ ] **Dashboards**: Cluster overview, GPU stats, Miner performance/profitability.
- [ ] **PriorityClasses**: Implement hierarchy to allow miner eviction:
    - `platform-*`: High priority (10000+).
    - `production-workloads`: Medium (3000).
    - `mining-workloads`: Negative (-1000) with `PreemptLowerPriority`.

## 🔐 Phase 3: Secrets & Identity (Vault Decided)
**Goal**: Centralized secret management and automated TLS.
- [ ] **Vault Auto-Unseal**: Configure Vault with **GCP Cloud KMS** (Keyring + CryptoKey).
- [ ] **Cert-Manager**: Deploy with Cloudflare DNS01 challenge.
- [ ] **External Secrets Operator (ESO)**: Integrate with GCP Secret Manager for non-Vault secrets (optional) or consolidate.
- [ ] **Secret Migration**: Move critical secrets (Argo admin, Grafana admin, Wallets) to Vault/GCP.
- [ ] **Cleanup**: Remove local secrets.

## 🌐 Phase 4: Networking & Exposure
**Goal**: Secure public access to `*.roura.xyz`.
- [ ] **Strategy**: Select/Implement exposure method (Cloudflare Tunnel vs Ingress+Proxy).
- [ ] **Gateway/Ingress**: Configure routes for ArgoCD, Grafana, Hubble.
- [ ] **Security**: Enforce TLS 1.3 and authentication for exposed endpoints.

## ⚙️ Phase 5: CI/CD & Governance
**Goal**: Automated pipelines and policy enforcement.
- [ ] **Argo Ecosystem**: Deploy Argo Events (EventBus) and Argo Workflows.
- [ ] **Pipelines**: Create workflows for Build/Push (Kaniko) and Remediation.
- [ ] **Kyverno**: Deploy admission controller.
- [ ] **Policies**: Enforce PSS (Pod Security Standards).
    - **Akash Tenants**: Enforce `runtimeClassName: gvisor` or `gvisor-gpu`.
    - **Miners**: Explicit exclusion (Privileged/HostNetwork required).

## 📊 Phase 6: Advanced Observability (SLOs & Logs)
**Goal**: Log aggregation, Service Level Objectives, and Advanced Alerting.
- [ ] **Loki + Fluent-Bit**: Centralized logging.
- [ ] **Pyrra**: Implement SLOs (Miner Uptime, GitOps Health, API Availability).
- [ ] **Advanced Alerting Strategy**:
    - **Deadman Switch**: Healthchecks.io integration (Webhook).
    - **Severity Routing**:
        - `critical` + `auto_remediate`: -> Argo Events.
        - `critical` + `no_remediate`: -> Slack/PagerDuty.
        - `warning`: -> Slack.
    - **Auto-Remediation**: Argo Events Sensors triggers workflows (e.g., restart miner, sync app).

## 🛡️ Phase 7: Hardening & Optimization
**Goal**: Production readiness.
- [ ] **Security**: Enforce Restricted PSS (except miners/Kaniko), NetworkPolicies (Default Deny).
- [ ] **Optimization**: VPA for platform apps, CPU Pinning review, Hugepages dynamic sizing.
- [ ] **Audit**: Extended audit logging (90 days).

## 🔮 Phase 8: Future Features
- [ ] **Backstage**: Developer Portal.
- [ ] **Velero**: Backup strategy (S3).
- [ ] **Storage**: Evaluate Longhorn migration.

## ⚠️ Architectural Decisions Required
1.  **Secret Store**: **DECIDED**: Vault with GCP Cloud KMS Auto-Unseal.
2.  **Alerting Strategy**: **DECIDED**: Healthchecks.io Deadman Switch + Multi-tier Severity Routing.
3.  **Exposure**: Confirm Cloudflare Tunnel vs Nginx Ingress.
4.  **Miner QoS**: Confirm "Negative Priority + Preemption" strategy.
5.  **Public Services**: Define which UIs are public vs VPN-only.
