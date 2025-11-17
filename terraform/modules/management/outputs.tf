output "automation_account_id" {
  description = "Automation Account ID"
  value       = azurerm_automation_account.main.id
}

output "automation_account_name" {
  description = "Automation Account name"
  value       = azurerm_automation_account.main.name
}

output "storage_account_id" {
  description = "Diagnostics Storage Account ID"
  value       = azurerm_storage_account.diagnostics.id
}

output "storage_account_name" {
  description = "Diagnostics Storage Account name"
  value       = azurerm_storage_account.diagnostics.name
}

output "recovery_vault_id" {
  description = "Recovery Services Vault ID"
  value       = azurerm_recovery_services_vault.main.id
}

output "recovery_vault_name" {
  description = "Recovery Services Vault name"
  value       = azurerm_recovery_services_vault.main.name
}

output "action_group_id" {
  description = "Monitor Action Group ID"
  value       = azurerm_monitor_action_group.main.id
}
