terraform {
  required_version = ">= 1.0"

  # https://developer.hashicorp.com/terraform/language/settings/backends/azurerm#example-configuration
  backend "azurerm" {
    container_name = "terraform"
    key            = "terraform.tfstate"
    use_oidc       = true

    # requires "Storage Blob Data Contributor" on the container
    use_azuread_auth = true
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
  use_oidc                   = true
  skip_provider_registration = true
  features {}
}
