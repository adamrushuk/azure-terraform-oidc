terraform {
  # https://github.com/hashicorp/terraform/releases
  required_version = ">= 1.3"

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
      version = "~> 3.29.1"
    }
    # https://github.com/terraform-providers/terraform-provider-azuread/releases
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.30.0"
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
