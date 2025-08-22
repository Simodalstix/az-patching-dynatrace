resource "azurerm_resource_group_policy_assignment" "vm_update_assessment" {
  name                 = "Enable-VM-Update-Assessment-For-${var.project_prefix}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15"
  display_name         = "Configure machines to receive Azure automatic VM guest OS patches by platform for ${var.project_prefix} Lab"
  description          = "Assigns a policy to enable automatic VM guest OS patching assessment for this lab environment."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "policy_assignment_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_resource_group_policy_assignment.vm_update_assessment.identity[0].principal_id
}