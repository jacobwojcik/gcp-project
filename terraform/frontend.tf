resource "null_resource" "frontend_image" {
  triggers = {
    docker_file = filemd5("../frontend/Dockerfile")
    source_code = sha256(join("", [for f in fileset("../frontend", "{*.ts,*.tsx,package.json}") : filemd5("../frontend/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOT
      # Check if image already exists
      if docker pull ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image}:latest 2>/dev/null; then
        echo "Image already exists and no changes detected, skipping build"
      else
        echo "[$(date)] Building and pushing frontend image..."
        cd ../frontend
        docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image} .
        gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet
        docker push ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.frontend_image}
        echo "[$(date)] Frontend image build complete"
      fi
    EOT
  }

  depends_on = [google_artifact_registry_repository.repo]
}

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

resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_service.frontend.name
  location = google_cloud_run_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
