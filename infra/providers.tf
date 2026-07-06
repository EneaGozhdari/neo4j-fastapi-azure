terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state backend — intentionally NOT configured for this exercise.
  # In a real environment state would live in an Azure Storage container with
  # locking. Uncomment and fill in to enable:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstateXXXXX"
  #   container_name       = "tfstate"
  #   key                  = "neo4j-fastapi-azure.tfstate"
  # }
}

provider "azurerm" {
  features {}

  # Required to plan/apply; supplied via variable so no real identifier is
  # committed. Not needed for `terraform validate` / `terraform fmt`.
  subscription_id = var.subscription_id
}
