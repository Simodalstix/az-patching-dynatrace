resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.project_prefix}-monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  tags = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                          = "dce-${var.project_prefix}-vmi"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule" "this" {
  name                        = "dcr-${var.project_prefix}-vmi"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.this.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      name                  = "log_analytics_destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Heartbeat", "Microsoft-Perf", "Microsoft-InsightsMetrics"]
    destinations = ["log_analytics_destination"]
  }

  data_sources {
    performance_counter {
      name                          = "PerfCounters"
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  for_each = { for idx, vm_id in var.vm_ids : idx => vm_id }

  name                    = "dcr-association-${var.project_prefix}-vm-${each.key}"
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id
  target_resource_id      = each.value
  description             = "Auto-associated via monitoring module"
}

resource "azurerm_monitor_data_collection_rule_association" "linux_vm" {
  for_each = { for idx, vm_id in var.vm_ids : idx => vm_id }

  name                    = "dcr-association-linux-vm-${each.key}"
  target_resource_id      = each.value
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id
  description             = "Association of Linux VM ${each.key} to VM Insights DCR"
}
