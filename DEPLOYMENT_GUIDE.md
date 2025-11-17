# Azure Landing Zone - Deployment Guide

This guide provides step-by-step instructions for deploying the Azure Landing Zone.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Deployment Planning](#pre-deployment-planning)
3. [Environment Setup](#environment-setup)
4. [Deployment Steps](#deployment-steps)
5. [Validation](#validation)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| Terraform | 1.5.0 | [Download](https://www.terraform.io/downloads) |
| Azure CLI | 2.50.0 | [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Git | 2.0+ | [Download](https://git-scm.com/downloads) |

### Azure Requirements

- Azure subscription with Owner or Contributor access
- Permissions to create management groups (if deploying management hierarchy)
- Service principal or user account with appropriate RBAC roles

### Verify Prerequisites

```bash
# Check Terraform version
terraform version

# Check Azure CLI version
az version

# Verify Azure login
az login
az account show
```

## Pre-Deployment Planning

### 1. Network Design

Plan your network architecture:

| Network | CIDR | Purpose |
|---------|------|---------|
| Hub | 10.0.0.0/16 | Central connectivity |
| Spoke 1 | 10.1.0.0/16 | Production workloads |
| Spoke 2 | 10.2.0.0/16 | Development workloads |
| Spoke 3 | 10.3.0.0/16 | Shared services |

**Important**: Ensure CIDR ranges don't overlap with on-premises networks or other Azure environments.

### 2. Resource Naming

Follow Azure naming conventions:

| Resource Type | Pattern | Example |
|--------------|---------|---------|
| Resource Group | rg-{env}-{purpose}-{region} | rg-prod-connectivity-eastus |
| Virtual Network | vnet-{env}-{purpose} | vnet-prod-hub |
| Subnet | snet-{purpose} | snet-web |
| NSG | nsg-{purpose} | nsg-web |

### 3. Cost Estimation

Estimate monthly costs for key components:

| Component | Dev | Prod | Notes |
|-----------|-----|------|-------|
| Azure Firewall | $0 | $1,000 | Standard tier |
| VPN Gateway | $0 | $150 | Basic SKU |
| Log Analytics | $50 | $200 | Based on ingestion |
| Defender for Cloud | $0 | $300 | ~20 VMs |
| Storage | $10 | $30 | Diagnostics |
| **Total** | **$60** | **$1,680** | Approximate |

### 4. Required Information

Gather the following information before deployment:

- [ ] Azure subscription ID
- [ ] Deployment region (e.g., eastus, westus2)
- [ ] Environment name (dev, staging, prod)
- [ ] Network CIDR ranges
- [ ] Security contact email
- [ ] Alert notification email
- [ ] Tags for resource organization

## Environment Setup

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd myfirstwebapp/terraform
```

### Step 2: Create Backend Storage

The Terraform state must be stored remotely for team collaboration and state locking.

```bash
#!/bin/bash

# Configuration
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="stterraform$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
echo "Creating resource group..."
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create storage account
echo "Creating storage account..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

# Create blob container
echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY

echo ""
echo "Backend storage created successfully!"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo ""
echo "Update backend.tfvars with these values"
```

### Step 3: Configure Backend

Create `backend.tfvars`:

```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraform<your-random-suffix>"
container_name       = "tfstate"
key                  = "landing-zone.tfstate"
```

### Step 4: Configure Variables

Create `terraform.tfvars`:

```hcl
# Basic Configuration
environment = "dev"
location    = "eastus"

# Management Groups
root_management_group_name = "My Organization"
root_management_group_id   = "myorg"

# Networking
hub_vnet_address_space = ["10.0.0.0/16"]

spoke_vnets = {
  "production" = {
    name          = "vnet-production"
    address_space = ["10.1.0.0/16"]
    subnets = {
      "web" = {
        address_prefix    = "10.1.1.0/24"
        service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      }
      "app" = {
        address_prefix    = "10.1.2.0/24"
        service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      }
      "data" = {
        address_prefix    = "10.1.3.0/24"
        service_endpoints = ["Microsoft.Sql"]
      }
    }
  }
}

# Features
enable_azure_firewall     = true
enable_vpn_gateway        = false
enable_defender_for_cloud = true

# Operations
log_retention_days = 30

# Tags
tags = {
  Project     = "Azure Landing Zone"
  CostCenter  = "IT"
  Owner       = "Platform Team"
  Environment = "Development"
}
```

## Deployment Steps

### Step 1: Initialize Terraform

```bash
terraform init -backend-config=backend.tfvars
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "azurerm"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 2: Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan carefully:
- Number of resources to be created
- Resource names and configurations
- Estimated costs

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

The deployment will take approximately 20-30 minutes. Monitor the output for any errors.

### Step 5: Save Outputs

After successful deployment:

```bash
terraform output > deployment-outputs.txt
```

## Validation

### 1. Verify Resource Groups

```bash
az group list --query "[?contains(name, '$ENVIRONMENT')].{Name:name, Location:location, ProvisioningState:properties.provisioningState}" -o table
```

### 2. Verify Virtual Networks

```bash
az network vnet list --query "[].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace.addressPrefixes}" -o table
```

### 3. Verify Network Peerings

```bash
az network vnet peering list --resource-group rg-dev-connectivity-eastus --vnet-name vnet-dev-hub-eastus -o table
```

### 4. Check Azure Firewall

```bash
az network firewall list --query "[].{Name:name, ResourceGroup:resourceGroup, PrivateIP:ipConfigurations[0].privateIpAddress}" -o table
```

### 5. Verify Log Analytics

```bash
az monitor log-analytics workspace list --query "[].{Name:name, ResourceGroup:resourceGroup, RetentionDays:retentionInDays}" -o table
```

### 6. Test Connectivity

From Azure Portal:
1. Navigate to Network Watcher
2. Run Connection troubleshoot between resources
3. Verify connectivity through hub

## Post-Deployment Configuration

### 1. Configure Azure Firewall Rules

```bash
# Example: Allow outbound HTTPS
az network firewall network-rule create \
  --resource-group rg-dev-connectivity-eastus \
  --firewall-name afw-dev-hub-eastus \
  --collection-name allow-outbound \
  --name allow-https \
  --protocols TCP \
  --source-addresses "*" \
  --destination-addresses "*" \
  --destination-ports 443 \
  --action Allow \
  --priority 100
```

### 2. Configure Role-Based Access Control

```bash
# Example: Assign Network Contributor role
az role assignment create \
  --assignee user@example.com \
  --role "Network Contributor" \
  --resource-group rg-dev-connectivity-eastus
```

### 3. Set Up Alerts

Review and customize monitor alerts in Azure Portal:
1. Navigate to Azure Monitor
2. Select Alerts
3. Review auto-created alert rules
4. Customize thresholds and action groups

### 4. Configure Backup Policies

Apply backup policies to virtual machines:
1. Navigate to Recovery Services Vault
2. Select Backup Policies
3. Review daily backup policy
4. Apply to VMs as they're created

### 5. Review Security Recommendations

```bash
# View Defender for Cloud recommendations
az security assessment list --query "[].{Name:displayName, Status:status.code, Severity:metadata.severity}" -o table
```

## Troubleshooting

### Issue: Backend Initialization Fails

**Error**: `Error: Failed to get existing workspaces`

**Solution**:
```bash
# Verify storage account access
az storage account show --name <storage-account-name> --resource-group rg-terraform-state

# Check permissions
az role assignment list --scope /subscriptions/<subscription-id>/resourceGroups/rg-terraform-state
```

### Issue: Insufficient Permissions

**Error**: `Authorization failed`

**Solution**:
```bash
# Check current role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Required roles:
# - Owner or Contributor on subscription
# - Management Group Contributor (for management groups)
```

### Issue: Resource Name Already Exists

**Error**: `A resource with the ID already exists`

**Solution**:
1. Modify resource name in variables
2. Add random suffix: `name = "resource-${random_string.suffix.result}"`

### Issue: Quota Exceeded

**Error**: `Operation results in exceeding quota limits`

**Solution**:
```bash
# Check current quota
az vm list-usage --location eastus -o table

# Request quota increase through Azure Portal
```

### Issue: Network CIDR Overlap

**Error**: `Address space overlaps with existing peered network`

**Solution**:
1. Review all CIDR ranges
2. Ensure no overlaps with:
   - Other Azure VNets
   - On-premises networks
   - VPN client address pools

## Rollback Procedure

If deployment fails or needs to be rolled back:

### Option 1: Destroy Specific Resources

```bash
# Destroy specific module
terraform destroy -target=module.networking
```

### Option 2: Complete Rollback

```bash
# WARNING: This destroys ALL resources
terraform destroy
```

### Option 3: Restore Previous State

```bash
# List state versions
az storage blob list \
  --account-name <storage-account> \
  --container-name tfstate \
  --query "[].{Name:name, LastModified:properties.lastModified}" -o table

# Download previous state
az storage blob download \
  --account-name <storage-account> \
  --container-name tfstate \
  --name landing-zone.tfstate \
  --file terraform.tfstate.backup
```

## Next Steps

After successful deployment:

1. **Documentation**: Document custom configurations and changes
2. **Monitoring**: Set up custom dashboards in Azure Monitor
3. **Security**: Complete security hardening checklist
4. **Training**: Train team on new infrastructure
5. **Migration**: Begin migrating workloads to landing zone

## Support

For assistance:
- Review logs: `terraform.log`
- Check Azure Activity Log in Portal
- Create issue in repository
- Consult Azure documentation

## Appendix

### A. Complete Validation Script

```bash
#!/bin/bash

echo "Validating Azure Landing Zone Deployment"
echo "=========================================="

# Check resource groups
echo -e "\n1. Resource Groups:"
az group list --query "[?tags.LandingZone=='Azure-Foundation'].{Name:name, Location:location}" -o table

# Check virtual networks
echo -e "\n2. Virtual Networks:"
az network vnet list --query "[].{Name:name, AddressSpace:addressSpace.addressPrefixes[0]}" -o table

# Check firewall
echo -e "\n3. Azure Firewall:"
az network firewall list --query "[].{Name:name, PrivateIP:ipConfigurations[0].privateIpAddress}" -o table

# Check Log Analytics
echo -e "\n4. Log Analytics Workspace:"
az monitor log-analytics workspace list --query "[].{Name:name, RetentionDays:retentionInDays}" -o table

# Check Key Vault
echo -e "\n5. Key Vault:"
az keyvault list --query "[].{Name:name, URI:properties.vaultUri}" -o table

echo -e "\nValidation complete!"
```

### B. Environment-Specific Configurations

See `environments/` directory for:
- `dev/dev.tfvars` - Development environment
- `staging/staging.tfvars` - Staging environment (create as needed)
- `prod/prod.tfvars` - Production environment (create as needed)
