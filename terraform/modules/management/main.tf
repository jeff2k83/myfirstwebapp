# Automation Account
resource "azurerm_automation_account" "main" {
  name                = "aa-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Link Automation Account to Log Analytics
resource "azurerm_log_analytics_linked_service" "automation" {
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  read_access_id      = azurerm_automation_account.main.id
}

# Storage Account for Diagnostics and Boot Diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                     = "stdiag${var.environment}${substr(md5(var.resource_group_name), 0, 8)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.storage_allowed_ips
    virtual_network_subnet_ids = []
  }

  tags = var.tags
}

# Storage Account for Flow Logs
resource "azurerm_storage_account" "flowlogs" {
  name                     = "stflow${var.environment}${substr(md5(var.resource_group_name), 0, 8)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# Recovery Services Vault
resource "azurerm_recovery_services_vault" "main" {
  name                = "rsv-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  soft_delete_enabled = true
  tags                = var.tags
}

# Backup Policy for VMs
resource "azurerm_backup_policy_vm" "daily" {
  name                = "backup-policy-daily"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 7
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.environment}-critical"
  resource_group_name = var.resource_group_name
  short_name          = "critical"
  tags                = var.tags

  email_receiver {
    name                    = "sendtoadmin"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  webhook_receiver {
    name                    = "callwebhook"
    service_uri             = var.alert_webhook_url
    use_common_alert_schema = true
  }
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-high-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.resource_group_name]
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Azure Monitor Workbook for Landing Zone Overview
resource "azurerm_application_insights_workbook" "landing_zone" {
  name                = "workbook-${var.environment}-overview"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "Landing Zone Overview"
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "## Azure Landing Zone - ${var.environment} Environment\n\nThis workbook provides an overview of your landing zone resources and their health status."
        }
      },
      {
        type = 3
        content = {
          version   = "KqlItem/1.0"
          query     = "Resources | summarize count() by type | order by count_ desc"
          size      = 0
          queryType = 1
          resourceType = "microsoft.resourcegraph/resources"
        }
      }
    ]
  })
  tags = var.tags
}
