#!/usr/bin/env python3
"""
Hospital ETL Pipeline - Cloud Run Version
Simple, reliable ETL without Dataproc complexity
"""

import os
import sys
import logging
from google.cloud import storage, bigquery
import pandas as pd
from datetime import datetime

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def download_csv_from_gcs(bucket_name, file_path, local_path):
    """Download CSV file from GCS to local storage"""
    logger.info(f"Downloading {file_path} from GCS bucket {bucket_name}")

    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(file_path)

    blob.download_to_filename(local_path)
    logger.info(f"Downloaded {file_path} successfully")


def process_patient_data(file_path):
    """Process patient data"""
    logger.info("Processing patient data...")

    df = pd.read_csv(file_path)

    # Data cleaning and transformation
    df["created_at"] = datetime.now()
    df["age"] = pd.to_numeric(df["age"], errors="coerce").fillna(0)
    df["gender"] = df["gender"].fillna("Unknown")
    df["condition"] = df["condition"].fillna("Unknown")

    logger.info(f"Processed {len(df)} patient records")
    return df


def process_treatment_data(file_path):
    """Process treatment data"""
    logger.info("Processing treatment data...")

    df = pd.read_csv(file_path)

    # Data cleaning and transformation
    df["created_at"] = datetime.now()
    df["cost"] = pd.to_numeric(df["cost"], errors="coerce").fillna(0)
    df["duration_days"] = pd.to_numeric(df["duration_days"], errors="coerce").fillna(0)
    df["treatment_type"] = df["treatment_type"].fillna("Unknown")

    logger.info(f"Processed {len(df)} treatment records")
    return df


def process_hospital_analysis_data(file_path):
    """Process hospital analysis data"""
    logger.info("Processing hospital analysis data...")

    df = pd.read_csv(file_path)

    # Data cleaning and transformation
    df["created_at"] = datetime.now()
    df["age"] = pd.to_numeric(df["age"], errors="coerce").fillna(0)
    df["cost"] = pd.to_numeric(df["cost"], errors="coerce").fillna(0)
    df["length_of_stay"] = pd.to_numeric(df["length_of_stay"], errors="coerce").fillna(
        0
    )
    df["satisfaction"] = pd.to_numeric(df["satisfaction"], errors="coerce").fillna(3)
    df["gender"] = df["gender"].fillna("Unknown")
    df["condition"] = df["condition"].fillna("Unknown")
    df["procedure"] = df["procedure"].fillna("Unknown")
    df["outcome"] = df["outcome"].fillna("Unknown")
    df["readmission"] = df["readmission"].fillna("No")

    logger.info(f"Processed {len(df)} hospital analysis records")
    return df


def upload_to_bigquery(df, project_id, dataset_id, table_id):
    """Upload DataFrame to BigQuery"""
    logger.info(f"Uploading data to BigQuery: {project_id}.{dataset_id}.{table_id}")

    client = bigquery.Client(project=project_id)
    table_ref = f"{project_id}.{dataset_id}.{table_id}"

    # Upload data
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",  # Replace existing data
        create_disposition="CREATE_IF_NEEDED",
    )

    job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
    job.result()  # Wait for job to complete

    logger.info(f"Successfully uploaded {len(df)} records to {table_ref}")


def main():
    """Main ETL function"""
    logger.info("Starting Hospital ETL Pipeline - Cloud Run Version")

    # Get configuration from environment variables
    project_id = os.getenv("PROJECT_ID", "pyspark-469619")
    raw_bucket = os.getenv("RAW_BUCKET", "hospital-raw-data-685c9129")
    dataset_id = os.getenv("DATASET_ID", "hospital_data")

    logger.info(f"Configuration:")
    logger.info(f"  Project ID: {project_id}")
    logger.info(f"  Raw Bucket: {raw_bucket}")
    logger.info(f"  Dataset ID: {dataset_id}")

    try:
        # Download and process patient data
        download_csv_from_gcs(raw_bucket, "data/raw/patients.csv", "/tmp/patients.csv")
        patient_df = process_patient_data("/tmp/patients.csv")
        upload_to_bigquery(patient_df, project_id, dataset_id, "patients")

        # Download and process treatment data
        download_csv_from_gcs(
            raw_bucket, "data/raw/treatments.csv", "/tmp/treatments.csv"
        )
        treatment_df = process_treatment_data("/tmp/treatments.csv")
        upload_to_bigquery(treatment_df, project_id, dataset_id, "treatments")

        # Download and process hospital analysis data
        download_csv_from_gcs(
            raw_bucket,
            "data/raw/hospital data analysis.csv",
            "/tmp/hospital_analysis.csv",
        )
        analysis_df = process_hospital_analysis_data("/tmp/hospital_analysis.csv")
        upload_to_bigquery(analysis_df, project_id, dataset_id, "hospital_analysis")

        logger.info("✅ ETL Pipeline completed successfully!")
        logger.info(f"📊 Data loaded to BigQuery: {project_id}.{dataset_id}")

        # Print summary
        logger.info(f"Summary:")
        logger.info(f"  - Processed {len(patient_df)} patient records")
        logger.info(f"  - Processed {len(treatment_df)} treatment records")
        logger.info(f"  - Processed {len(analysis_df)} hospital analysis records")

    except Exception as e:
        logger.error(f"❌ ETL Pipeline failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
