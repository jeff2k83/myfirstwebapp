# Azure Landing Zone Architecture

## Overview

This document describes the architecture of the Azure Landing Zone implementation, following Microsoft's Cloud Adoption Framework (CAF) best practices.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                               │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Management Group Hierarchy                       │ │
│  │                                                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │                      Root Management Group                    │ │ │
│  │  │                                                               │ │ │
│  │  │  ┌─────────────────┐         ┌──────────────────────────┐  │ │ │
│  │  │  │   Platform      │         │   Landing Zones          │  │ │ │
│  │  │  │                 │         │                          │  │ │ │
│  │  │  │ ┌─────────────┐ │         │ ┌──────────────────────┐│  │ │ │
│  │  │  │ │Connectivity │ │         │ │  Corp                ││  │ │ │
│  │  │  │ └─────────────┘ │         │ └──────────────────────┘│  │ │ │
│  │  │  │ ┌─────────────┐ │         │ ┌──────────────────────┐│  │ │ │
│  │  │  │ │Management   │ │         │ │  Online              ││  │ │ │
│  │  │  │ └─────────────┘ │         │ └──────────────────────┘│  │ │ │
│  │  │  │ ┌─────────────┐ │         │                          │  │ │ │
│  │  │  │ │Identity     │ │         │                          │  │ │ │
│  │  │  │ └─────────────┘ │         │                          │  │ │ │
│  │  │  └─────────────────┘         └──────────────────────────┘  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Hub-Spoke Network Topology

```
                              ┌──────────────────────────┐
                              │    On-Premises Network   │
                              │                          │
                              └────────────┬─────────────┘
                                           │
                                     VPN/ExpressRoute
                                           │
┌──────────────────────────────────────────┼────────────────────────────────────┐
│                                          │                                     │
│                                 ┌────────▼────────┐                           │
│                                 │  VPN Gateway    │                           │
│                                 └────────┬────────┘                           │
│                                          │                                     │
│    ┌─────────────────────────────────────┴──────────────────────────────┐    │
│    │                         Hub Virtual Network                         │    │
│    │                         CIDR: 10.0.0.0/16                          │    │
│    │                                                                     │    │
│    │  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │    │
│    │  │ Azure Firewall  │  │  Azure Bastion   │  │ Shared Services  │ │    │
│    │  │ 10.0.0.0/24     │  │  10.0.2.0/24     │  │  10.0.3.0/24     │ │    │
│    │  └────────┬────────┘  └──────────────────┘  └──────────────────┘ │    │
│    │           │                                                        │    │
│    └───────────┼────────────────────────────────────────────────────────┘    │
│                │                                                              │
│       ┌────────┼────────┬─────────────────────┬─────────────────────┐       │
│       │        │        │                     │                     │       │
│  ┌────▼─────┐ │ ┌──────▼──────┐     ┌────────▼────────┐  ┌────────▼─────┐ │
│  │ Spoke 1  │ │ │  Spoke 2    │     │    Spoke 3      │  │   Spoke N    │ │
│  │Production│ │ │Development  │     │Shared Services  │  │   Future     │ │
│  │10.1.0.0/16  │ │10.2.0.0/16  │     │10.3.0.0/16      │  │10.N.0.0/16   │ │
│  │          │ │ │             │     │                 │  │              │ │
│  │ ┌──────┐ │ │ │ ┌────────┐ │     │ ┌─────────────┐ │  │              │ │
│  │ │ Web  │ │ │ │ │  App   │ │     │ │  DevOps     │ │  │              │ │
│  │ └──────┘ │ │ │ └────────┘ │     │ └─────────────┘ │  │              │ │
│  │ ┌──────┐ │ │ │            │     │                 │  │              │ │
│  │ │ App  │ │ │ │            │     │                 │  │              │ │
│  │ └──────┘ │ │ │            │     │                 │  │              │ │
│  │ ┌──────┐ │ │ │            │     │                 │  │              │ │
│  │ │ Data │ │ │ │            │     │                 │  │              │ │
│  │ └──────┘ │ │ │            │     │                 │  │              │ │
│  └──────────┘ │ └────────────┘     └─────────────────┘  └──────────────┘ │
│               │                                                            │
└───────────────┴────────────────────────────────────────────────────────────┘

              All traffic flows through Azure Firewall in Hub
```

## Component Architecture

### 1. Management Groups

```
Root (org-root)
├── Platform
│   ├── Connectivity (Network resources)
│   ├── Management (Monitoring, automation)
│   └── Identity (IAM, AD)
└── Landing Zones
    ├── Corp (Corporate workloads)
    └── Online (Internet-facing workloads)
```

**Purpose:**
- Organize subscriptions hierarchically
- Apply policies and RBAC at scale
- Separate concerns (platform vs. workloads)

### 2. Resource Groups

| Resource Group | Purpose | Resources |
|----------------|---------|-----------|
| rg-{env}-connectivity | Networking | VNets, Firewall, Bastion, VPN Gateway |
| rg-{env}-management | Operations | Log Analytics, Automation, Storage |
| rg-{env}-identity | Identity | Key Vault, AD-related resources |

### 3. Networking Components

#### Hub Virtual Network
- **CIDR**: 10.0.0.0/16
- **Subnets**:
  - `AzureFirewallSubnet`: 10.0.0.0/24 (Azure Firewall)
  - `GatewaySubnet`: 10.0.1.0/24 (VPN/ExpressRoute Gateway)
  - `AzureBastionSubnet`: 10.0.2.0/24 (Azure Bastion)
  - `SharedServicesSubnet`: 10.0.3.0/24 (Shared services)

#### Spoke Virtual Networks
- **Production Spoke**: 10.1.0.0/16
  - Web tier: 10.1.1.0/24
  - App tier: 10.1.2.0/24
  - Data tier: 10.1.3.0/24

- **Development Spoke**: 10.2.0.0/16
  - App tier: 10.2.1.0/24

- **Additional Spokes**: 10.N.0.0/16

#### Network Security

```
Internet
    │
    ▼
┌───────────────┐
│ Azure Firewall│ ──────┐
└───────────────┘       │
    │                   │ Inspects & Filters
    ▼                   │
┌───────────────┐       │
│  Hub VNet     │◄──────┘
└───────┬───────┘
        │
   ┌────┴────┬─────────┬──────────┐
   ▼         ▼         ▼          ▼
Spoke 1  Spoke 2   Spoke 3    Spoke N
   │         │         │          │
   ▼         ▼         ▼          ▼
  NSG       NSG       NSG        NSG
```

### 4. Security Architecture

#### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Azure Policy                                           │
│ - Enforce compliance                                            │
│ - Restrict resource locations                                  │
│ - Require tags                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Network Security                                       │
│ - Azure Firewall (L4-L7 filtering)                            │
│ - Network Security Groups (L4 filtering)                       │
│ - DDoS Protection                                              │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Identity & Access                                      │
│ - Azure AD integration                                         │
│ - RBAC assignments                                             │
│ - Managed identities                                           │
│ - Key Vault for secrets                                        │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: Threat Protection                                      │
│ - Microsoft Defender for Cloud                                 │
│ - Security alerts and recommendations                          │
│ - Vulnerability scanning                                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 5: Monitoring & Response                                  │
│ - Log Analytics                                                │
│ - Azure Monitor                                                │
│ - Security Center alerts                                       │
│ - Automated responses                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 5. Management and Operations

```
┌─────────────────────────────────────────────────────────────────┐
│                    Log Analytics Workspace                       │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐    │
│  │  Security    │  │   Updates    │  │  Change Tracking  │    │
│  │  Solution    │  │   Solution   │  │     Solution      │    │
│  └──────────────┘  └──────────────┘  └───────────────────┘    │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Monitor                               │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐    │
│  │    Alerts    │  │  Workbooks   │  │   Action Groups   │    │
│  └──────────────┘  └──────────────┘  └───────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Azure Automation                               │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐    │
│  │   Runbooks   │  │   Update     │  │   Configuration   │    │
│  │              │  │  Management  │  │    Management     │    │
│  └──────────────┘  └──────────────┘  └───────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 6. Data Flow

#### Inbound Traffic Flow

```
Internet
    │
    ├─── DDoS Protection
    │
    ▼
Public Load Balancer / Application Gateway
    │
    ├─── WAF (if App Gateway)
    │
    ▼
Azure Firewall (DNAT)
    │
    ├─── Application Rules
    ├─── Network Rules
    │
    ▼
Hub VNet
    │
    ▼
Spoke VNet (via peering)
    │
    ├─── NSG Rules
    │
    ▼
Application Subnet
    │
    ▼
Application Resources
```

#### Outbound Traffic Flow

```
Application Resources
    │
    ├─── NSG Rules
    │
    ▼
Spoke VNet
    │
    ├─── UDR (Route to Firewall)
    │
    ▼
Hub VNet
    │
    ▼
Azure Firewall
    │
    ├─── Application Rules
    ├─── Network Rules
    │
    ▼
Internet / Azure Services
```

#### East-West Traffic (Between Spokes)

```
Spoke 1
    │
    ├─── NSG
    │
    ▼
Hub VNet (via peering)
    │
    ▼
Azure Firewall
    │
    ├─── Network Rules
    │
    ▼
Hub VNet
    │
    ▼
Spoke 2 (via peering)
    │
    ├─── NSG
    │
    ▼
Application Resources
```

## Key Design Decisions

### 1. Hub-Spoke vs. Virtual WAN
**Decision**: Hub-Spoke topology
**Rationale**:
- More control over routing and security
- Cost-effective for medium-scale deployments
- Familiar architecture for most teams
- Gradual migration path to Virtual WAN if needed

### 2. Azure Firewall vs. NVA
**Decision**: Azure Firewall
**Rationale**:
- Native Azure service with full integration
- Automatic scaling and high availability
- Microsoft support and SLA
- Built-in threat intelligence

### 3. Management Group Structure
**Decision**: Platform and Landing Zones separation
**Rationale**:
- Clear separation of concerns
- Different RBAC and policy requirements
- Supports organizational growth
- Aligns with CAF recommendations

### 4. Network Segmentation
**Decision**: /24 subnets for most workloads
**Rationale**:
- Sufficient IP addresses (254 usable)
- Allows for growth within subnets
- Standard subnet size for many organizations
- Simplifies IP planning

## Scalability Considerations

### Network Scaling

| Aspect | Current | Maximum | Notes |
|--------|---------|---------|-------|
| Hub VNet | 1 | 1 per region | Additional hubs for other regions |
| Spoke VNets | 2-5 | 500 | Per hub (peering limit) |
| Subnets per VNet | 3-5 | 3000 | Practical limit ~100 |
| VMs per subnet | 10-50 | ~65000 | Based on /24 subnet |

### Management Scaling

| Component | Current | Scaling Strategy |
|-----------|---------|------------------|
| Log Analytics | 1 workspace | Regional workspaces for compliance |
| Automation Account | 1 account | Per region or workload type |
| Recovery Vault | 1 vault | Per region for DR |
| Key Vault | 1 vault | Per application or compliance boundary |

## High Availability and Disaster Recovery

### HA Design

```
Region 1 (Primary)              Region 2 (Secondary)
┌─────────────────┐            ┌─────────────────┐
│   Hub VNet 1    │            │   Hub VNet 2    │
│   10.0.0.0/16   │◄──Global──►│   10.100.0.0/16 │
│                 │   Peering  │                 │
│ ┌─────────────┐ │            │ ┌─────────────┐ │
│ │   Firewall  │ │            │ │   Firewall  │ │
│ │   (Active)  │ │            │ │  (Standby)  │ │
│ └─────────────┘ │            │ └─────────────┘ │
│                 │            │                 │
│ ┌─────────────┐ │            │ ┌─────────────┐ │
│ │  Spoke 1    │ │            │ │  Spoke 1    │ │
│ │  (Active)   │ │            │ │  (Standby)  │ │
│ └─────────────┘ │            │ └─────────────┘ │
└─────────────────┘            └─────────────────┘
```

### DR Strategy

- **RPO (Recovery Point Objective)**: 1 hour
- **RTO (Recovery Time Objective)**: 4 hours
- **Backup Frequency**: Daily
- **Geo-Replication**: Enabled for critical data

## Cost Optimization

### Cost Breakdown (Monthly Estimates)

| Component | Dev | Prod | Notes |
|-----------|-----|------|-------|
| Azure Firewall | $0 | $1,000 | Disable in dev |
| VPN Gateway | $0 | $150 | Only if needed |
| Bastion | $140 | $140 | Required for secure access |
| Log Analytics | $50 | $200 | Based on ingestion |
| Storage | $10 | $30 | Diagnostics and logs |
| Defender for Cloud | $0 | $300 | Disable in dev |
| **Total** | **$200** | **$1,820** | Approximate |

### Cost Optimization Tips

1. **Dev environments**: Disable Firewall, VPN, and Defender
2. **Log retention**: Reduce to 7-30 days in non-prod
3. **Reserved instances**: For always-on resources
4. **Auto-shutdown**: Configure for dev/test VMs
5. **Right-sizing**: Regularly review and adjust SKUs

## Security Controls

### Implemented Controls

| Control | Implementation | Purpose |
|---------|----------------|---------|
| Network isolation | Hub-spoke topology | Segregate workloads |
| Traffic inspection | Azure Firewall | Monitor/filter traffic |
| Identity management | Azure AD + RBAC | Control access |
| Secrets management | Key Vault | Protect credentials |
| Threat detection | Defender for Cloud | Identify threats |
| Compliance | Azure Policy | Enforce standards |
| Monitoring | Log Analytics | Audit and alert |
| Backup | Recovery Services | Data protection |

## Compliance and Governance

### Azure Policy Assignments

1. **Allowed Locations**: Restrict deployment regions
2. **Required Tags**: Enforce tagging standards
3. **Managed Disks**: Audit unmanaged disks
4. **TLS Version**: Enforce minimum TLS 1.2
5. **Public Access**: Restrict public endpoints

### Tagging Strategy

| Tag | Purpose | Example |
|-----|---------|---------|
| Environment | Deployment stage | dev, staging, prod |
| CostCenter | Billing allocation | IT, Finance, Marketing |
| Owner | Responsible team | Platform Team |
| Project | Initiative | Landing Zone |
| Compliance | Requirements | PCI-DSS, HIPAA |

## References

- [Azure Landing Zones](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Hub-Spoke Network Topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Security Baseline](https://docs.microsoft.com/en-us/security/benchmark/azure/)
