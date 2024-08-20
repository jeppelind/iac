terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraformGrp" {
  name     = "terraformGroup"
  location = "Sweden Central"

  tags = {
    Environment = "Terraform Test"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "terraformVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraformGrp.location
  resource_group_name = azurerm_resource_group.terraformGrp.name
}