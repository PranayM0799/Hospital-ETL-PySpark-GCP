#!/usr/bin/env python3
"""
Hospital ETL Pipeline - PySpark Version
Runs the complete ETL pipeline using PySpark on Dataproc
"""

import sys
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, when, to_date, to_timestamp, year, month, dayofweek,
    datediff, concat, lit, current_timestamp
)
from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, DoubleType, TimestampType
)
from google.cloud import storage
from google.cloud import bigquery
import logging
import argparse

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_spark_session():
    """Create and configure Spark session"""
    spark = SparkSession.builder \
        .appName("HospitalETLPipeline") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .config("spark.sql.adaptive.skewJoin.enabled", "true") \
        .getOrCreate()

    # Set log level to reduce noise
    spark.sparkContext.setLogLevel("WARN")

    return spark


def read_patient_data(spark, input_path):
    """Read patient data from GCS"""
    logger.info(f"Reading patient data from: {input_path}")

    # Define schema for patient data
    patient_schema = StructType([
        StructField("patient_id", StringType(), True),
        StructField("first_name", StringType(), True),
        StructField("last_name", StringType(), True),
        StructField("date_of_birth", StringType(), True),
        StructField("gender", StringType(), True),
        StructField("admission_date", StringType(), True),
        StructField("discharge_date", StringType(), True),
        StructField("diagnosis", StringType(), True),
        StructField("created_at", StringType(), True)
    ])

    try:
        df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "false") \
            .schema(patient_schema) \
            .csv(input_path)

        logger.info(f"Successfully read {df.count()} patient records")
        return df
    except Exception as e:
        logger.error(f"Error reading patient data: {str(e)}")
        raise


def read_treatment_data(spark, input_path):
    """Read treatment data from GCS"""
    logger.info(f"Reading treatment data from: {input_path}")

    # Define schema for treatment data
    treatment_schema = StructType([
        StructField("treatment_id", StringType(), True),
        StructField("patient_id", StringType(), True),
        StructField("treatment_type", StringType(), True),
        StructField("treatment_date", StringType(), True),
        StructField("doctor_name", StringType(), True),
        StructField("treatment_notes", StringType(), True),
        StructField("cost", StringType(), True),
        StructField("created_at", StringType(), True)
    ])

    try:
        df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "false") \
            .schema(treatment_schema) \
            .csv(input_path)

        logger.info(f"Successfully read {df.count()} treatment records")
        return df
    except Exception as e:
        logger.error(f"Error reading treatment data: {str(e)}")
        raise


def transform_patient_data(df):
    """Transform and clean patient data"""
    logger.info("Starting patient data transformation")

    # Convert date columns to proper types
    df_transformed = df.withColumn(
        "date_of_birth",
        to_date(col("date_of_birth"), "yyyy-MM-dd")
    ).withColumn(
        "admission_date",
        to_timestamp(col("admission_date"), "yyyy-MM-dd HH:mm:ss")
    ).withColumn(
        "discharge_date",
        to_timestamp(col("discharge_date"), "yyyy-MM-dd HH:mm:ss")
    ).withColumn(
        "created_at",
        to_timestamp(col("created_at"), "yyyy-MM-dd HH:mm:ss")
    )

    # Add calculated fields
    df_transformed = df_transformed.withColumn(
        "age_at_admission",
        year(col("admission_date")) - year(col("date_of_birth"))
    ).withColumn(
        "length_of_stay_days",
        datediff(col("discharge_date"), col("admission_date"))
    ).withColumn(
        "full_name",
        concat(col("first_name"), lit(" "), col("last_name"))
    )

    # Add data quality flags
    df_transformed = df_transformed.withColumn(
        "has_valid_dates",
        when(
            col("admission_date").isNotNull() & col("discharge_date").isNotNull(),
            True) .otherwise(False)).withColumn(
        "has_valid_diagnosis",
        when(
            col("diagnosis").isNotNull() & (
                col("diagnosis") != ""),
            True) .otherwise(False))

    # Add processing timestamp
    df_transformed = df_transformed.withColumn(
        "processed_at",
        current_timestamp()
    )

    logger.info("Patient data transformation completed")
    return df_transformed


def transform_treatment_data(df):
    """Transform and clean treatment data"""
    logger.info("Starting treatment data transformation")

    # Convert date columns to proper types
    df_transformed = df.withColumn(
        "treatment_date",
        to_timestamp(col("treatment_date"), "yyyy-MM-dd HH:mm:ss")
    ).withColumn(
        "created_at",
        to_timestamp(col("created_at"), "yyyy-MM-dd HH:mm:ss")
    ).withColumn(
        "cost",
        col("cost").cast(DoubleType())
    )

    # Add calculated fields
    df_transformed = df_transformed.withColumn(
        "treatment_year",
        year(col("treatment_date"))
    ).withColumn(
        "treatment_month",
        month(col("treatment_date"))
    ).withColumn(
        "treatment_day_of_week",
        dayofweek(col("treatment_date"))
    ).withColumn(
        "cost_category",
        when(col("cost") >= 5000, "High Cost")
        .when(col("cost") >= 1000, "Medium Cost")
        .when(col("cost") >= 100, "Low Cost")
        .otherwise("Minimal Cost")
    )

    # Add data quality flags
    df_transformed = df_transformed.withColumn(
        "has_valid_cost",
        when(
            col("cost").isNotNull() & (
                col("cost") >= 0),
            True) .otherwise(False)).withColumn(
        "has_valid_doctor",
                when(
                    col("doctor_name").isNotNull() & (
                        col("doctor_name") != ""),
                    True) .otherwise(False)).withColumn(
        "has_valid_treatment_type",
        when(
            col("treatment_type").isNotNull() & (
                col("treatment_type") != ""),
            True) .otherwise(False))

    # Add processing timestamp
    df_transformed = df_transformed.withColumn(
        "processed_at",
        current_timestamp()
    )

    logger.info("Treatment data transformation completed")
    return df_transformed


def read_hospital_analysis_data(spark, input_path):
    """Read hospital analysis data from GCS"""
    logger.info(f"Reading hospital analysis data from: {input_path}")

    # Define schema for hospital analysis data
    analysis_schema = StructType([
        StructField("patient_id", StringType(), True),
        StructField("age", IntegerType(), True),
        StructField("gender", StringType(), True),
        StructField("condition", StringType(), True),
        StructField("procedure", StringType(), True),
        StructField("cost", DoubleType(), True),
        StructField("length_of_stay", IntegerType(), True),
        StructField("readmission", StringType(), True),
        StructField("outcome", StringType(), True),
        StructField("satisfaction", IntegerType(), True)
    ])

    df = spark.read \
        .option("header", "true") \
        .option("inferSchema", "false") \
        .schema(analysis_schema) \
        .csv(input_path)

    logger.info(f"Successfully read {df.count()} hospital analysis records")
    return df


def transform_hospital_analysis_data(df):
    """Transform hospital analysis data"""
    logger.info("Starting hospital analysis data transformation")

    # Add created_at timestamp
    df_transformed = df.withColumn("created_at", current_timestamp())

    # Data cleaning and validation
    df_transformed = df_transformed.withColumn(
        "gender",
        when(
            col("gender").isNull(),
            "Unknown").otherwise(
            col("gender")))

    df_transformed = df_transformed.withColumn(
        "condition",
        when(
            col("condition").isNull(),
            "Unknown").otherwise(
            col("condition")))

    df_transformed = df_transformed.withColumn(
        "procedure",
        when(
            col("procedure").isNull(),
            "Unknown").otherwise(
            col("procedure")))

    df_transformed = df_transformed.withColumn(
        "outcome",
        when(
            col("outcome").isNull(),
            "Unknown").otherwise(
            col("outcome")))

    df_transformed = df_transformed.withColumn(
        "readmission", when(
            col("readmission").isNull(), "No").otherwise(
            col("readmission")))

    # Ensure satisfaction is between 1-5
    df_transformed = df_transformed.withColumn(
        "satisfaction",
        when(
            col("satisfaction").isNull(),
            3) .when(
            col("satisfaction") < 1,
            1) .when(
                col("satisfaction") > 5,
                5) .otherwise(
                    col("satisfaction")))

    # Ensure age is reasonable (0-120)
    df_transformed = df_transformed.withColumn("age",
                                               when(col("age").isNull(), 0)
                                               .when(col("age") < 0, 0)
                                               .when(col("age") > 120, 120)
                                               .otherwise(col("age")))

    # Ensure cost is non-negative
    df_transformed = df_transformed.withColumn("cost",
                                               when(col("cost").isNull(), 0.0)
                                               .when(col("cost") < 0, 0.0)
                                               .otherwise(col("cost")))

    # Ensure length_of_stay is non-negative
    df_transformed = df_transformed.withColumn(
        "length_of_stay",
        when(
            col("length_of_stay").isNull(),
            0) .when(
            col("length_of_stay") < 0,
            0) .otherwise(
                col("length_of_stay")))

    logger.info("Hospital analysis data transformation completed")
    return df_transformed


def validate_data(df, data_type):
    """Validate data quality"""
    logger.info(f"Starting {data_type} data validation")

    total_records = df.count()
    logger.info(f"Total records to validate: {total_records}")

    if data_type == "patient":
        # Check for null values in critical fields
        null_patient_ids = df.filter(col("patient_id").isNull()).count()
        null_names = df.filter(col("first_name").isNull()
                               | col("last_name").isNull()).count()
        null_dates = df.filter(col("admission_date").isNull() | col(
            "discharge_date").isNull()).count()

        logger.info(f"Records with null patient_id: {null_patient_ids}")
        logger.info(f"Records with null names: {null_names}")
        logger.info(f"Records with null dates: {null_dates}")

        # Check for duplicate patient IDs
        duplicate_patient_ids = df.groupBy(
            "patient_id").count().filter(col("count") > 1).count()
        logger.info(f"Duplicate patient IDs: {duplicate_patient_ids}")

        if null_patient_ids > 0 or duplicate_patient_ids > 0:
            logger.warning("Patient data quality issues detected!")
            return False

    elif data_type == "treatment":
        # Check for null values in critical fields
        null_treatment_ids = df.filter(col("treatment_id").isNull()).count()
        null_patient_ids = df.filter(col("patient_id").isNull()).count()
        null_treatment_types = df.filter(
            col("treatment_type").isNull()).count()
        null_costs = df.filter(col("cost").isNull()).count()

        logger.info(f"Records with null treatment_id: {null_treatment_ids}")
        logger.info(f"Records with null patient_id: {null_patient_ids}")
        logger.info(
            f"Records with null treatment_type: {null_treatment_types}")
        logger.info(f"Records with null cost: {null_costs}")

        # Check for duplicate treatment IDs
        duplicate_treatment_ids = df.groupBy(
            "treatment_id").count().filter(col("count") > 1).count()
        logger.info(f"Duplicate treatment IDs: {duplicate_treatment_ids}")

        if null_treatment_ids > 0 or duplicate_treatment_ids > 0:
            logger.warning("Treatment data quality issues detected!")
            return False

    elif data_type == "hospital_analysis":
        # Check for null values in critical fields
        null_patient_ids = df.filter(col("patient_id").isNull()).count()
        null_ages = df.filter(col("age").isNull()).count()
        null_genders = df.filter(col("gender").isNull()).count()
        null_conditions = df.filter(col("condition").isNull()).count()

        logger.info(f"Records with null patient_id: {null_patient_ids}")
        logger.info(f"Records with null age: {null_ages}")
        logger.info(f"Records with null gender: {null_genders}")
        logger.info(f"Records with null condition: {null_conditions}")

        # Check for duplicate patient IDs
        duplicate_patient_ids = df.groupBy(
            "patient_id").count().filter(col("count") > 1).count()
        logger.info(f"Duplicate patient IDs: {duplicate_patient_ids}")

        if null_patient_ids > 0 or duplicate_patient_ids > 0:
            logger.warning("Hospital analysis data quality issues detected!")
            return False

    logger.info(f"{data_type} data validation passed")
    return True


def write_to_bigquery(df, project_id, dataset_id, table_id):
    """Write data to BigQuery"""
    logger.info(
        f"Writing data to BigQuery: {project_id}.{dataset_id}.{table_id}")

    try:
        # Select only the columns that match the BigQuery schema
        if table_id == "patients":
            # Select only the original columns for patients table
            df_to_write = df.select(
                "patient_id",
                "first_name",
                "last_name",
                "date_of_birth",
                "gender",
                "admission_date",
                "discharge_date",
                "diagnosis",
                "created_at")
        elif table_id == "treatments":
            # Select only the original columns for treatments table
            df_to_write = df.select(
                "treatment_id",
                "patient_id",
                "treatment_type",
                "treatment_date",
                "doctor_name",
                "treatment_notes",
                "cost",
                "created_at")
        elif table_id == "hospital_analysis":
            # Select only the original columns for hospital analysis table
            df_to_write = df.select(
                "patient_id",
                "age",
                "gender",
                "condition",
                "procedure",
                "cost",
                "length_of_stay",
                "readmission",
                "outcome",
                "satisfaction",
                "created_at")
        else:
            df_to_write = df

        # Write to BigQuery using Spark BigQuery connector (indirect method)
        df_to_write.write \
            .format("bigquery") \
            .option("table", f"{project_id}.{dataset_id}.{table_id}") \
            .option("writeMethod", "indirect") \
            .option("temporaryGcsBucket", "hospital-processed-data-1ed88d11") \
            .option("createDisposition", "CREATE_IF_NEEDED") \
            .option("writeDisposition", "WRITE_TRUNCATE") \
            .mode("overwrite") \
            .save()

        logger.info("Successfully wrote data to BigQuery")

    except Exception as e:
        logger.error(f"Error writing to BigQuery: {str(e)}")
        raise


def main():
    """Main ETL function"""
    parser = argparse.ArgumentParser(description='Hospital ETL Pipeline')
    parser.add_argument('--project-id', required=True, help='GCP Project ID')
    parser.add_argument(
        '--raw-bucket',
        required=True,
        help='Raw data bucket name')
    parser.add_argument(
        '--dataset-id',
        default='hospital_data',
        help='BigQuery dataset ID')

    args = parser.parse_args()

    logger.info("Starting Hospital ETL Pipeline")
    logger.info(f"Project ID: {args.project_id}")
    logger.info(f"Raw Bucket: {args.raw_bucket}")
    logger.info(f"Dataset ID: {args.dataset_id}")

    try:
        # Create Spark session
        spark = create_spark_session()

        # Process patient data
        logger.info("Processing patient data...")
        patient_df = read_patient_data(
            spark, f"gs://{args.raw_bucket}/data/raw/patients.csv")
        patient_transformed = transform_patient_data(patient_df)

        if not validate_data(patient_transformed, "patient"):
            logger.error("Patient data validation failed. Exiting.")
            sys.exit(1)

        write_to_bigquery(
            patient_transformed,
            args.project_id,
            args.dataset_id,
            "patients")

        # Process treatment data
        logger.info("Processing treatment data...")
        treatment_df = read_treatment_data(
            spark, f"gs://{args.raw_bucket}/data/raw/treatments.csv")
        treatment_transformed = transform_treatment_data(treatment_df)

        if not validate_data(treatment_transformed, "treatment"):
            logger.error("Treatment data validation failed. Exiting.")
            sys.exit(1)

        write_to_bigquery(
            treatment_transformed,
            args.project_id,
            args.dataset_id,
            "treatments")

        # Process hospital analysis data
        logger.info("Processing hospital analysis data...")
        analysis_df = read_hospital_analysis_data(
            spark, f"gs://{args.raw_bucket}/data/raw/hospital data analysis.csv")
        analysis_transformed = transform_hospital_analysis_data(analysis_df)

        if not validate_data(analysis_transformed, "hospital_analysis"):
            logger.error("Hospital analysis data validation failed. Exiting.")
            sys.exit(1)

        write_to_bigquery(
            analysis_transformed,
            args.project_id,
            args.dataset_id,
            "hospital_analysis")

        logger.info("ETL pipeline completed successfully!")

        # Show summary statistics
        patient_count = patient_transformed.count()
        treatment_count = treatment_transformed.count()
        analysis_count = analysis_transformed.count()

        logger.info(f"Summary:")
        logger.info(f"- Processed {patient_count} patient records")
        logger.info(f"- Processed {treatment_count} treatment records")
        logger.info(f"- Processed {analysis_count} hospital analysis records")
        logger.info(
            f"- Data loaded to BigQuery: {args.project_id}.{args.dataset_id}")

    except Exception as e:
        logger.error(f"ETL pipeline failed: {str(e)}")
        sys.exit(1)

    finally:
        if 'spark' in locals():
            spark.stop()


if __name__ == "__main__":
    main()
