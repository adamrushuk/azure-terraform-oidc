resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.rg_name}"
  location = var.location
  tags     = var.tags
}
