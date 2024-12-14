resource "null_resource" "backend_image" {
  triggers = {
    docker_file = filemd5("../backend/Dockerfile")
    source_dir  = sha256(join("", [for f in fileset("../backend", "**"): filemd5("../backend/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Starting backend image build..."
      cd ../backend
      echo "Building backend Docker image..."
      docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image} . || exit 1
      echo "Configuring Docker authentication..."
      gcloud auth configure-docker ${var.region}-docker.pkg.dev || exit 1
      echo "Pushing backend image..."
      docker push ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image} || exit 1
      echo "Backend image build and push complete"
    EOT
  }

  depends_on = [google_artifact_registry_repository.repo]
}

# Cloud Run service for backend
resource "google_cloud_run_service" "backend" {
  name     = "backend-service"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image}"
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository.repo,
    null_resource.backend_image
  ]
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
