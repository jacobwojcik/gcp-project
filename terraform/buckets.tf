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

# Add IAM permissions for Cloud Run service account
resource "google_storage_bucket_iam_member" "backend_original_bucket" {
  bucket = google_storage_bucket.original_images.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}

resource "google_storage_bucket_iam_member" "backend_processed_bucket" {
  bucket = google_storage_bucket.processed_images.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}

# Add IAM permissions for Cloud Function
resource "google_storage_bucket_iam_member" "function_original_bucket" {
  bucket = google_storage_bucket.original_images.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_cloudfunctions_function.image_processor.service_account_email}"
}

resource "google_storage_bucket_iam_member" "function_processed_bucket" {
  bucket = google_storage_bucket.processed_images.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_cloudfunctions_function.image_processor.service_account_email}"
}
