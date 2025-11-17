# Azure Landing Zone - Terraform Implementation

This repository contains a complete Azure Landing Zone implementation using Terraform, following Microsoft's Cloud Adoption Framework (CAF) best practices.

## Architecture Overview

This landing zone implements a comprehensive Azure foundation with the following components:

### Management Group Hierarchy
- **Root Management Group**: Top-level organizational structure
  - **Platform**: Platform-level services
    - **Connectivity**: Networking and connectivity resources
    - **Management**: Monitoring and management tools
    - **Identity**: Identity and access management
  - **Landing Zones**: Application workload subscriptions

### Hub-Spoke Network Topology
- **Hub VNet**: Central hub for shared services
  - Azure Firewall for traffic inspection and filtering
  - Azure Bastion for secure VM access
  - VPN Gateway (optional) for hybrid connectivity
  - Shared services subnet
- **Spoke VNets**: Isolated workload networks
  - Peered to hub for centralized connectivity
  - Network Security Groups (NSGs) for traffic control
  - Service endpoints for Azure PaaS services

### Security and Governance
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Microsoft Defender for Cloud**: Security posture management
- **Azure Policy**: Compliance and governance enforcement
- **Key Vault**: Secrets and certificate management
- **Network Watcher**: Network diagnostics and monitoring

### Management and Operations
- **Azure Automation**: Runbook automation and update management
- **Recovery Services Vault**: Backup and disaster recovery
- **Storage Accounts**: Diagnostics and flow logs
- **Azure Monitor**: Alerts and workbooks

## Prerequisites

Before deploying this landing zone, ensure you have:

1. **Azure Subscription**: Active Azure subscription with Owner or Contributor access
2. **Terraform**: Version 1.5.0 or later ([Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
3. **Azure CLI**: Latest version ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
4. **Permissions**: Ability to create management groups and assign policies

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd myfirstwebapp/terraform
```

### 2. Authenticate to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 3. Create Backend Storage (First Time Setup)

Create a storage account for Terraform state:

```bash
# Set variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="stterraformstate$RANDOM"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

### 4. Configure Backend

Copy the backend configuration template and update with your values:

```bash
cp backend.tfvars.example backend.tfvars
# Edit backend.tfvars with your storage account details
```

### 5. Configure Variables

Copy the variables template and customize for your environment:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

### 6. Initialize Terraform

```bash
terraform init -backend-config=backend.tfvars
```

### 7. Plan Deployment

Review the resources that will be created:

```bash
terraform plan -out=tfplan
```

### 8. Apply Configuration

Deploy the landing zone:

```bash
terraform apply tfplan
```

## Project Structure

```
terraform/
├── main.tf                  # Root module - orchestrates all components
├── variables.tf             # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example variable values
├── backend.tfvars.example  # Backend configuration template
├── .gitignore              # Git ignore rules
├── modules/
│   ├── networking/         # Hub-spoke network topology
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/          # Security and governance
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── management/        # Management and monitoring
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/              # Environment-specific configurations
        └── dev.tfvars
```

## Module Documentation

### Networking Module

Implements hub-spoke network topology with:
- Hub virtual network with firewall, bastion, and gateway subnets
- Spoke virtual networks with customizable subnets
- VNet peering between hub and spokes
- Azure Firewall for centralized traffic control
- Azure Bastion for secure VM access
- Network Security Groups

**Key Variables:**
- `hub_vnet_address_space`: Hub network CIDR (default: 10.0.0.0/16)
- `spoke_vnets`: Map of spoke networks with subnets
- `enable_azure_firewall`: Enable/disable Azure Firewall (default: true)
- `enable_vpn_gateway`: Enable/disable VPN Gateway (default: false)

### Security Module

Provides security and compliance foundation:
- Log Analytics workspace with security solutions
- Key Vault for secrets management
- Microsoft Defender for Cloud
- Azure Policy assignments

**Key Variables:**
- `log_retention_days`: Log retention period (default: 30)
- `enable_defender_for_cloud`: Enable Defender (default: true)
- `allowed_locations`: Permitted Azure regions
- `security_contact_email`: Email for security alerts

### Management Module

Operational management capabilities:
- Azure Automation account
- Recovery Services Vault with backup policies
- Storage accounts for diagnostics
- Azure Monitor alerts and workbooks

**Key Variables:**
- `alert_email`: Email for operational alerts
- `storage_allowed_ips`: IPs allowed to access storage

## Configuration Examples

### Example 1: Basic Development Environment

```hcl
environment = "dev"
location    = "eastus"

hub_vnet_address_space = ["10.0.0.0/16"]

spoke_vnets = {
  "app" = {
    name          = "vnet-app"
    address_space = ["10.1.0.0/16"]
    subnets = {
      "web" = {
        address_prefix    = "10.1.1.0/24"
        service_endpoints = ["Microsoft.Storage"]
      }
    }
  }
}

enable_azure_firewall     = false  # Save costs in dev
enable_defender_for_cloud = false  # Save costs in dev
```

### Example 2: Production Environment

```hcl
environment = "prod"
location    = "eastus"

hub_vnet_address_space = ["10.0.0.0/16"]

spoke_vnets = {
  "production" = {
    name          = "vnet-production"
    address_space = ["10.1.0.0/16"]
    subnets = {
      "web"  = { address_prefix = "10.1.1.0/24", service_endpoints = ["Microsoft.Storage"] }
      "app"  = { address_prefix = "10.1.2.0/24", service_endpoints = ["Microsoft.Sql"] }
      "data" = { address_prefix = "10.1.3.0/24", service_endpoints = ["Microsoft.Sql"] }
    }
  }
  "shared" = {
    name          = "vnet-shared"
    address_space = ["10.2.0.0/16"]
    subnets = {
      "services" = { address_prefix = "10.2.1.0/24", service_endpoints = ["Microsoft.Storage"] }
    }
  }
}

enable_azure_firewall     = true
enable_vpn_gateway        = true
log_retention_days        = 90
enable_defender_for_cloud = true
```

## Deployment Stages

For large deployments, consider phased approach:

### Phase 1: Foundation
```bash
terraform apply -target=azurerm_management_group.root
terraform apply -target=azurerm_resource_group.connectivity
terraform apply -target=azurerm_resource_group.management
```

### Phase 2: Networking
```bash
terraform apply -target=module.networking
```

### Phase 3: Security and Management
```bash
terraform apply -target=module.security
terraform apply -target=module.management
```

### Phase 4: Full Deployment
```bash
terraform apply
```

## Post-Deployment Tasks

After successful deployment:

1. **Review Resources**: Check Azure Portal for created resources
2. **Configure Firewall Rules**: Add necessary firewall rules in Azure Firewall
3. **Set Up RBAC**: Assign roles to users and service principals
4. **Configure Monitoring**: Review and customize alert rules
5. **Update DNS**: Configure DNS settings for name resolution
6. **Test Connectivity**: Verify network connectivity between hub and spokes

## Cost Optimization

To reduce costs in non-production environments:

```hcl
enable_azure_firewall     = false  # ~$1,000/month
enable_vpn_gateway        = false  # ~$150/month
enable_defender_for_cloud = false  # ~$15/server/month
log_retention_days        = 7      # Reduce storage costs
```

## Security Considerations

1. **Secrets Management**: Never commit `*.tfvars` files with sensitive data
2. **State File**: Store state file in encrypted Azure Storage with access controls
3. **Service Principals**: Use managed identities where possible
4. **Network Security**: Review NSG rules regularly
5. **Compliance**: Ensure Azure Policy assignments meet your requirements

## Troubleshooting

### Common Issues

**Issue**: Terraform init fails with backend error
```bash
# Solution: Verify backend.tfvars has correct storage account details
# Ensure you have access to the storage account
```

**Issue**: Insufficient permissions
```bash
# Solution: Ensure you have Owner or Contributor role on the subscription
# For management groups, you need Management Group Contributor role
```

**Issue**: Resource name conflicts
```bash
# Solution: Resource names must be globally unique
# Modify variables to use unique names (e.g., add random suffix)
```

## Maintenance

### Updating Infrastructure

```bash
# Pull latest changes
git pull

# Review changes
terraform plan

# Apply updates
terraform apply
```

### Destroying Resources

**WARNING**: This will delete all resources!

```bash
# Destroy specific module
terraform destroy -target=module.networking

# Destroy everything
terraform destroy
```

## Contributing

1. Create a feature branch
2. Make changes and test thoroughly
3. Submit pull request with description
4. Ensure all checks pass

## Additional Resources

- [Azure Landing Zone Documentation](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)

## Support

For issues and questions:
- Create an issue in this repository
- Review Terraform documentation
- Consult Azure documentation

## License

This project is licensed under the MIT License - see LICENSE file for details.
