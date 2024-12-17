terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "archive" {}
provider "null" {}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com"
  ])
  project = var.project_id
  service = each.key

  disable_dependent_services = true
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "app-images"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}
