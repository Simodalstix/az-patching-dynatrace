# Azure PatchLab Infrastructure

This project provisions a complete Azure lab environment designed for patching, monitoring, and observability use cases. It includes:

- Modular Terraform code using best practices
- Linux (RHEL 9) and Windows Server VMs
- Azure Monitor integration via Data Collection Rules (DCR)
- Log Analytics Workspace & custom performance counters
- Dynatrace OneAgent deployment on all VMs
- Public Load Balancer with dedicated subnets
- Secure remote access (RDP/SSH via whitelisted IPs)

---

## Architecture Overview

- **Virtual Network** with separate subnets for web and app tiers
- **Availability Sets** for Linux and Windows VMs
- **Azure Monitor Agent (AMA)** installed automatically via DCR
- **Log Analytics Workspace** used for performance monitoring
- **Dynatrace OneAgent** deployed via cloud-init/PowerShell
- **Load Balancer** configured with public IP for lab testing

---

## Modules Breakdown

| Module       | Description                                 |
| ------------ | ------------------------------------------- |
| `linux-vm`   | Deploys RHEL VMs + Dynatrace                |
| `windows-vm` | Deploys Windows VM + Dynatrace              |
| `monitoring` | Sets up DCE, DCR, Log Analytics + links VMs |

---

## Usage

### 1. Clone this repo

```bash
git clone https://github.com/yourusername/azure-patchlab.git
cd azure-patchlab
```

### 2. Set your secrets

Edit `terraform.tfvars` or export them as env vars:

```hcl
dynatrace_environment_url = "https://yourtenant.live.dynatrace.com"
dynatrace_api_token       = "dt0c01.XXX..."
```

### 3. Initialize + plan

```bash
terraform init
terraform plan
```

### 4. Apply it

```bash
terraform apply
```

---

## Monitoring & Observability

Azure Monitor:

- View VM metrics in Log Analytics → “Heartbeat” or “Perf”
- Customize queries for processor, memory, disk

Dynatrace:

- OneAgent auto-deploys on VM boot
- Logs & performance data should appear under Hosts
- Future enhancements:
  - Create Dashboards
  - Set up Alert Workflows
  - Enable Log Ingestion (Syslog / Windows Events)

---

## Security Notes

- Public access to RDP and SSH is **locked to whitelisted IPs**.
- All secrets (admin passwords, Dynatrace tokens) are stored securely using Terraform’s `sensitive` flag.
- AMA installs only with system-assigned identities and DCR associations.

---

## Future Work

- [ ] Azure Update Manager integration for patch automation
- [ ] Dynatrace dashboards + alert workflows
- [ ] Add NSG logging and diagnostics settings
- [ ] Private DNS or custom domain support
- [ ] Optional Bastion host for secure access

---

## Directory Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── linux-vm/
│   ├── windows-vm/
│   └── monitoring/
├── scripts/
│   ├── install_dynatrace_rhel.sh
│   └── install_dynatrace_windows.ps1
```

---

## License

MIT — use freely, give credit if helpful.
