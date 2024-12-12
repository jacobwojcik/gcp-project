# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Storage Bucket for Original Images
resource "google_storage_bucket" "original_images" {
  name          = var.original_bucket_name
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = var.original_bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# Storage Bucket for Processed Images
resource "google_storage_bucket" "processed_images" {
  name          = var.processed_bucket_name
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = var.processed_bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }
}
