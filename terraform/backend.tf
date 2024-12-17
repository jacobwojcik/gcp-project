resource "null_resource" "backend_image" {
  triggers = {
    docker_file = filemd5("../backend/Dockerfile")
    source_code = sha256(join("", [for f in fileset("../backend", "{*.ts,package.json}") : filemd5("../backend/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOT
      if docker pull ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image}:latest 2>/dev/null; then
        echo "Image already exists and no changes detected, skipping build"
      else
        echo "[$(date)] Building and pushing backend image..."
        cd ../backend
        docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image} .
        gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet
        docker push ${var.region}-docker.pkg.dev/${var.project_id}/app-images/${var.backend_image}
        echo "[$(date)] Backend image build complete"
      fi
    EOT
  }

  depends_on = [google_artifact_registry_repository.repo]
}

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

resource "google_cloud_run_service_iam_member" "backend_public" {
  service  = google_cloud_run_service.backend.name
  location = google_cloud_run_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_cloud_run_service.backend.template[0].spec[0].service_account_name}"
}
