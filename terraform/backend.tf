# Cloud Run service for backend
resource "google_cloud_run_service" "backend" {
  name     = "backend-service"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image}"
      }
    }
  }

  depends_on = [google_artifact_registry_repository.repo]
}

# Make the service public
resource "google_cloud_run_service_iam_member" "backend_public" {
  service  = google_cloud_run_service.backend.name
  location = google_cloud_run_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Add IAM role binding for metrics
resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}

# Add IAM role binding for logs
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}
