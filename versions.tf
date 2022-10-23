terraform {
  required_version = ">= 1.0"

  # terraform remote state
  backend "azurerm" {
    # resource_group_name  = "arsh-rg-tfstate"
    # storage_account_name = "arshsttfstateeastus"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }

  required_providers {
    # https://github.com/terraform-providers/terraform-provider-azurerm/releases
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.28.0"
    }
    # https://github.com/terraform-providers/terraform-provider-azuread/releases
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.29.0"
    }
  }
}

# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc#configuring-the-service-principal-in-terraform
  use_oidc = true

  # TODO
  # SP requires "Storage Blob Data Contributor" on the container
  # use_azuread_auth = true

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
  features {
    resource_group {
      # required to cleanup velero snapshot(s) from resource group
      prevent_deletion_if_contains_resources = false
    }
  }
}
