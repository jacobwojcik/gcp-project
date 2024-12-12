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


variable "original_bucket_name" {
  description = "Name of the bucket for storing original images"
  type        = string
}

variable "processed_bucket_name" {
  description = "Name of the bucket for storing processed images"
  type        = string
}

variable "original_bucket_retention_days" {
  description = "Retention period (in days) for original images"
  type        = number
  default     = 30
}

variable "processed_bucket_retention_days" {
  description = "Retention period (in days) for processed images"
  type        = number
  default     = 90
}