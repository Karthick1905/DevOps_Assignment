variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "tenanthub-prod"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "sql_instance_name" {
  description = "Existing Cloud SQL PostgreSQL instance name"
  type        = string
  default     = "shared-postgres"
}
