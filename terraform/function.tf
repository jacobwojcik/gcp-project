resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-source"
  location = var.region
}

data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/files/function.zip"
  source {
    content  = file("${path.module}/files/index.js")
    filename = "index.js"
  }
  source {
    content  = file("${path.module}/files/package.json")
    filename = "package.json"
  }
}

resource "google_storage_bucket_object" "function_code" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Create Pub/Sub topic
resource "google_pubsub_topic" "image_processing" {
  name = "image-processing-topic"
}

# Create Cloud Function
resource "google_cloudfunctions_function" "image_processor" {
  name        = "image-processor"
  description = "Function to process uploaded images"
  runtime     = "nodejs18"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  entry_point          = "processImage"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.image_processing.name
  }

  environment_variables = {
    ORIGINAL_BUCKET  = var.original_bucket_name
    PROCESSED_BUCKET = var.processed_bucket_name
  }
}

data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "publisher" {
  topic  = google_pubsub_topic.image_processing.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Create bucket notification AFTER IAM permissions are set
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.original_images.name
  payload_format = "JSON_API_V1"
  topic         = google_pubsub_topic.image_processing.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [
    google_pubsub_topic.image_processing,
    google_pubsub_topic_iam_member.publisher
  ]
}
