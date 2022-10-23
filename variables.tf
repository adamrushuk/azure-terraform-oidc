variable "location" {
  description = "Location used for Azure resources"
  default     = "eastus"
}

variable "rg_name" {
  description = "Resource group name"
  default     = "rg-azure-terraform-oidc"
}

variable "tags" {
  description = "A map of tags to use on the resources"
  default = {
    Owner  = "Adam Rush"
    Source = "azure-terraform-oidc_github"
  }
}
