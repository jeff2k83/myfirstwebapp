variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for management resources"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "storage_allowed_ips" {
  description = "IP addresses allowed to access storage accounts"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "admin@example.com"
}

variable "alert_webhook_url" {
  description = "Webhook URL for alerts"
  type        = string
  default     = "https://example.com/webhook"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
