variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "management_resource_group" {
  description = "Management resource group name"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "enable_defender_for_cloud" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = true
}

variable "security_contact_email" {
  description = "Security contact email for alerts"
  type        = string
  default     = "security@example.com"
}

variable "security_contact_phone" {
  description = "Security contact phone number"
  type        = string
  default     = "+1-555-0100"
}

variable "key_vault_allowed_ips" {
  description = "IP addresses allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_locations" {
  description = "Allowed Azure regions for resources"
  type        = list(string)
  default     = ["eastus", "eastus2", "westus", "westus2"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
