variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "backend_image" {
  description = "Backend Docker image name"
  type        = string
  default     = "backend"
}

variable "frontend_image" {
  description = "Frontend Docker image name"
  type        = string
  default     = "frontend"
}
