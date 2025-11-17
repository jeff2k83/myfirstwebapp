variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "root_management_group_name" {
  description = "Display name for the root management group"
  type        = string
  default     = "Organization Root"
}

variable "root_management_group_id" {
  description = "ID for the root management group"
  type        = string
  default     = "org-root"
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnets" {
  description = "Map of spoke virtual networks"
  type = map(object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefix = string
      service_endpoints = list(string)
    }))
  }))
  default = {
    "workload1" = {
      name          = "vnet-workload1"
      address_space = ["10.1.0.0/16"]
      subnets = {
        "app" = {
          address_prefix    = "10.1.1.0/24"
          service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
        }
        "data" = {
          address_prefix    = "10.1.2.0/24"
          service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
        }
      }
    }
    "workload2" = {
      name          = "vnet-workload2"
      address_space = ["10.2.0.0/16"]
      subnets = {
        "app" = {
          address_prefix    = "10.2.1.0/24"
          service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
        }
      }
    }
  }
}

variable "enable_azure_firewall" {
  description = "Enable Azure Firewall in the hub"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway in the hub"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "enable_defender_for_cloud" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Azure Landing Zone"
    CostCenter  = "IT"
    Compliance  = "Required"
  }
}
