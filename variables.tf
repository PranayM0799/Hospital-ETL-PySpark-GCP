# Project configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "pyspark-469619"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-b"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# BigQuery configuration
variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for hospital data"
  type        = string
  default     = "hospital_data"
}

# Composer configuration
variable "composer_image_version" {
  description = "Cloud Composer image version"
  type        = string
  default     = "composer-2.0.31-airflow-2.2.5"
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.0.0/24"
}
