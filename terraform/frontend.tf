resource "null_resource" "frontend_image" {
  triggers = {
    docker_file = filemd5("../frontend/Dockerfile")
    source_dir  = sha256(join("", [for f in fileset("../frontend", "**"): filemd5("../frontend/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Starting frontend image build..."
      cd ../frontend
      echo "Building frontend Docker image..."
      docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image} . || exit 1
      echo "Configuring Docker authentication..."
      gcloud auth configure-docker ${var.region}-docker.pkg.dev || exit 1
      echo "Pushing frontend image..."
      docker push ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image} || exit 1
      echo "Frontend image build and push complete"
    EOT
  }

  depends_on = [google_artifact_registry_repository.repo]
}

# Cloud Run service for frontend
resource "google_cloud_run_service" "frontend" {
  name     = "frontend-service"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image}"
        env {
          name  = "BACKEND_URL"
          value = google_cloud_run_service.backend.status[0].url
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository.repo,
    null_resource.frontend_image
  ]
}

# Make the service public
resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_service.frontend.name
  location = google_cloud_run_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
