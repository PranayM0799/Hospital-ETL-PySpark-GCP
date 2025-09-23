# Configure the Google Cloud provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "dataproc.googleapis.com"
  ])

  service                    = each.value
  disable_dependent_services = false
}

# Create GCS bucket for raw data
resource "google_storage_bucket" "raw_data_bucket" {
  name          = "hospital-raw-data-${random_id.bucket_suffix.hex}"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Create GCS bucket for processed data
resource "google_storage_bucket" "processed_data_bucket" {
  name          = "hospital-processed-data-${random_id.bucket_suffix.hex}"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = true
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create BigQuery dataset for hospital data
resource "google_bigquery_dataset" "hospital_dataset" {
  dataset_id  = "hospital_data"
  description = "Dataset for hospital ETL data"
  location    = "US"

  labels = {
    environment = "production"
    project     = "hospital-etl"
  }
}

# Create BigQuery table for patient data
resource "google_bigquery_table" "patient_table" {
  dataset_id = google_bigquery_dataset.hospital_dataset.dataset_id
  table_id   = "patients"
  
  schema = file("${path.module}/schemas/patient_schema.json")
  
  deletion_protection = false
  
  labels = {
    environment = "production"
    table_type  = "patient_data"
  }
}

# Create BigQuery table for treatment data
resource "google_bigquery_table" "treatment_table" {
  dataset_id = google_bigquery_dataset.hospital_dataset.dataset_id
  table_id   = "treatments"
  
  schema = file("${path.module}/schemas/treatment_schema.json")
  
  deletion_protection = false
  
  labels = {
    environment = "production"
    table_type  = "treatment_data"
  }
}

# Create BigQuery table for hospital analysis data
resource "google_bigquery_table" "hospital_analysis_table" {
  dataset_id = google_bigquery_dataset.hospital_dataset.dataset_id
  table_id   = "hospital_analysis"
  
  schema = file("${path.module}/schemas/hospital_analysis_schema.json")
  
  deletion_protection = false
  
  labels = {
    environment = "production"
    table_type  = "analysis_data"
  }
}

# Create service account for Dataproc
resource "google_service_account" "dataproc_sa" {
  account_id   = "dataproc-sa"
  display_name = "Service Account for Dataproc"
}

# Note: IAM roles are already granted to dataproc-sa service account
# The following roles are already assigned:
# - roles/storage.admin
# - roles/bigquery.admin  
# - roles/dataproc.worker

# Output important values
output "raw_data_bucket" {
  value = google_storage_bucket.raw_data_bucket.name
}

output "processed_data_bucket" {
  value = google_storage_bucket.processed_data_bucket.name
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.hospital_dataset.dataset_id
}

output "project_id" {
  value = var.project_id
}