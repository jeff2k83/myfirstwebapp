terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  backend "azurerm" {
    # Backend configuration should be provided via backend config file or CLI
    # Example: terraform init -backend-config=backend.tfvars
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}

# Create management groups hierarchy
resource "azurerm_management_group" "root" {
  display_name = var.root_management_group_name
  name         = var.root_management_group_id
}

resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  name                       = "platform"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "landing_zones" {
  display_name               = "Landing Zones"
  name                       = "landing-zones"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "connectivity" {
  display_name               = "Connectivity"
  name                       = "connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "management" {
  display_name               = "Management"
  name                       = "management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "identity" {
  display_name               = "Identity"
  name                       = "identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

# Core resource groups
resource "azurerm_resource_group" "connectivity" {
  name     = "rg-${var.environment}-connectivity-${var.location}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "management" {
  name     = "rg-${var.environment}-management-${var.location}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "identity" {
  name     = "rg-${var.environment}-identity-${var.location}"
  location = var.location
  tags     = local.common_tags
}

# Networking Module - Hub-Spoke Topology
module "networking" {
  source = "./modules/networking"

  environment           = var.environment
  location              = var.location
  resource_group_name   = azurerm_resource_group.connectivity.name
  hub_vnet_address_space = var.hub_vnet_address_space
  spoke_vnets           = var.spoke_vnets
  enable_azure_firewall = var.enable_azure_firewall
  enable_vpn_gateway    = var.enable_vpn_gateway
  tags                  = local.common_tags
}

# Security and Governance Module
module "security" {
  source = "./modules/security"

  environment                = var.environment
  location                   = var.location
  management_resource_group  = azurerm_resource_group.management.name
  log_retention_days         = var.log_retention_days
  enable_defender_for_cloud  = var.enable_defender_for_cloud
  tags                       = local.common_tags
}

# Management and Monitoring Module
module "management" {
  source = "./modules/management"

  environment               = var.environment
  location                  = var.location
  resource_group_name       = azurerm_resource_group.management.name
  log_analytics_workspace_id = module.security.log_analytics_workspace_id
  tags                      = local.common_tags
}

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      LandingZone = "Azure-Foundation"
      DeployedOn  = timestamp()
    }
  )
}
