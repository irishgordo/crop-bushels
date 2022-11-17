terraform {
  required_providers {
    harvester = {
      source = "harvester/harvester"
      version = "0.6.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.16.0"
    }
  }
}

provider "harvester" {
  # Configuration options
  kubeconfig = var.KUBECONFIG_LOCATION
}

provider "kubernetes" {
  config_path = var.KUBECONFIG_LOCATION
}