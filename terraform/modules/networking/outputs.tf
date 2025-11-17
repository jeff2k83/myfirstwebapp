output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_ids" {
  description = "Map of spoke VNet IDs"
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "spoke_vnet_names" {
  description = "Map of spoke VNet names"
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.name }
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address"
  value       = var.enable_azure_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}

output "bastion_id" {
  description = "Azure Bastion ID"
  value       = azurerm_bastion_host.hub.id
}

output "network_watcher_id" {
  description = "Network Watcher ID"
  value       = azurerm_network_watcher.main.id
}
