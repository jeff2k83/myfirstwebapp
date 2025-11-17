output "management_groups" {
  description = "Management group IDs"
  value = {
    root          = azurerm_management_group.root.id
    platform      = azurerm_management_group.platform.id
    landing_zones = azurerm_management_group.landing_zones.id
    connectivity  = azurerm_management_group.connectivity.id
    management    = azurerm_management_group.management.id
    identity      = azurerm_management_group.identity.id
  }
}

output "resource_groups" {
  description = "Core resource group names"
  value = {
    connectivity = azurerm_resource_group.connectivity.name
    management   = azurerm_resource_group.management.name
    identity     = azurerm_resource_group.identity.name
  }
}

output "networking" {
  description = "Networking configuration details"
  value = {
    hub_vnet_id    = module.networking.hub_vnet_id
    hub_vnet_name  = module.networking.hub_vnet_name
    spoke_vnet_ids = module.networking.spoke_vnet_ids
    firewall_ip    = module.networking.firewall_private_ip
  }
  sensitive = false
}

output "security" {
  description = "Security configuration details"
  value = {
    log_analytics_workspace_id   = module.security.log_analytics_workspace_id
    log_analytics_workspace_name = module.security.log_analytics_workspace_name
    key_vault_id                 = module.security.key_vault_id
  }
  sensitive = false
}

output "management" {
  description = "Management and monitoring details"
  value = {
    automation_account_id = module.management.automation_account_id
    storage_account_id    = module.management.storage_account_id
  }
  sensitive = false
}
