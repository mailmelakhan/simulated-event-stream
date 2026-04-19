terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.24.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.24.0"
    }
  }
}

provider "google" {
  # Configuration options
  project = var.project_id
}

locals {
  services = [
    "bigquery.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "dataflow.googleapis.com",
    "managedkafka.googleapis.com",
    "workflows.googleapis.com",
    "iam.googleapis.com"
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key
  disable_on_destroy = false
}
