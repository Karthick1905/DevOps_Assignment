terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "tenant_acme_corp" {
  source = "./modules/tenant"

  project_id        = var.project_id
  region            = var.region
  sql_instance_name = var.sql_instance_name
  tenant_name       = "acme-corp"
  db_name           = "acme_corp"
  db_user           = "acme_corp_user"
  k8s_namespace     = "acme-corp"
  k8s_serviceaccount = "acme-corp-sa"
}
