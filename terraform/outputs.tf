output "backend_url" {
  value = google_cloud_run_service.backend.status[0].url
}

output "frontend_url" {
  value = google_cloud_run_service.frontend.status[0].url
}

output "original_bucket_url" {
  value = google_storage_bucket.original_images.url
}

output "processed_bucket_url" {
  value = google_storage_bucket.processed_images.url
}
