variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for networking resources"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for hub VNet"
  type        = list(string)
}

variable "spoke_vnets" {
  description = "Map of spoke virtual networks"
  type = map(object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefix    = string
      service_endpoints = list(string)
    }))
  }))
}

variable "enable_azure_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
