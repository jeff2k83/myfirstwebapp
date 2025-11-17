data "azurerm_client_config" "current" {}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.management_resource_group
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "security" {
  solution_name         = "Security"
  location              = var.location
  resource_group_name   = var.management_resource_group
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }
}

resource "azurerm_log_analytics_solution" "updates" {
  solution_name         = "Updates"
  location              = var.location
  resource_group_name   = var.management_resource_group
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }
}

resource "azurerm_log_analytics_solution" "change_tracking" {
  solution_name         = "ChangeTracking"
  location              = var.location
  resource_group_name   = var.management_resource_group
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ChangeTracking"
  }
}

resource "azurerm_log_analytics_solution" "vm_insights" {
  solution_name         = "VMInsights"
  location              = var.location
  resource_group_name   = var.management_resource_group
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment}-${substr(md5(var.management_resource_group), 0, 8)}"
  location                   = var.location
  resource_group_name        = var.management_resource_group
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.key_vault_allowed_ips
  }

  tags = var.tags
}

# Key Vault Access Policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Purge", "GetRotationPolicy"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "ManageContacts", "GetIssuers", "ListIssuers"
  ]
}

# Microsoft Defender for Cloud
resource "azurerm_security_center_workspace" "main" {
  count = var.enable_defender_for_cloud ? 1 : 0

  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_security_center_subscription_pricing" "vms" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "app_services" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "sql_servers" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "containers" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "Containers"
}

resource "azurerm_security_center_subscription_pricing" "keyvaults" {
  count = var.enable_defender_for_cloud ? 1 : 0

  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_contact" "main" {
  count = var.enable_defender_for_cloud ? 1 : 0

  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = true
  alerts_to_admins    = true
}

# Azure Policy Assignments
resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "require-tags"
  resource_group_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.management_resource_group}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Require specified tag on resource groups"
  display_name         = "Require tag on resource groups"

  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "This policy enables you to restrict the locations your organization can specify when deploying resources"
  display_name         = "Allowed locations"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

resource "azurerm_subscription_policy_assignment" "audit_vms_without_managed_disks" {
  name                 = "audit-vms-no-managed-disks"
  subscription_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
  description          = "Audit VMs that do not use managed disks"
  display_name         = "Audit VMs that do not use managed disks"
}
