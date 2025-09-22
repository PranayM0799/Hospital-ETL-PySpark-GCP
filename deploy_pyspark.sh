#!/bin/bash

# PySpark Hospital ETL Pipeline Deployment Script
# This script deploys the ETL pipeline using PySpark on Dataproc

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="pyspark-469619"
REGION="us-central1"
ZONE="us-central1-a"

echo -e "${BLUE}🚀 PySpark Hospital ETL Pipeline Deployment${NC}"
echo "============================================="

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Set the project
echo -e "${YELLOW}📋 Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}🔧 Enabling required APIs...${NC}"
gcloud services enable storage.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable dataproc.googleapis.com

# Initialize Terraform
echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"
terraform init

# Plan Terraform deployment
echo -e "${YELLOW}📋 Planning Terraform deployment...${NC}"
terraform plan

# Ask for confirmation
echo -e "${YELLOW}❓ Do you want to proceed with the deployment? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # Apply Terraform
    echo -e "${YELLOW}🚀 Deploying infrastructure...${NC}"
    terraform apply -auto-approve
    
    # Get outputs
    RAW_BUCKET=$(terraform output -raw raw_data_bucket)
    PROCESSED_BUCKET=$(terraform output -raw processed_data_bucket)
    BIGQUERY_DATASET=$(terraform output -raw bigquery_dataset)
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    echo ""
    echo -e "${GREEN}📊 Deployment Summary:${NC}"
    echo "Project ID: $PROJECT_ID"
    echo "Region: $REGION"
    echo "Raw Data Bucket: $RAW_BUCKET"
    echo "Processed Data Bucket: $PROCESSED_BUCKET"
    echo "BigQuery Dataset: $BIGQUERY_DATASET"
    echo ""
    
    # Upload sample data and scripts
    echo -e "${YELLOW}📤 Uploading sample data and scripts...${NC}"
    
    # Upload sample data
    gsutil cp data/raw/patients.csv gs://$RAW_BUCKET/data/raw/
    gsutil cp data/raw/treatments.csv gs://$RAW_BUCKET/data/raw/
    gsutil cp "data/raw/hospital data analysis.csv" gs://$RAW_BUCKET/data/raw/
    
    # Upload ETL script
    gsutil cp run_etl.py gs://$PROCESSED_BUCKET/scripts/
    
    echo -e "${GREEN}✅ Sample data and scripts uploaded!${NC}"
    echo ""
    
    # Create and run Dataproc job
    echo -e "${YELLOW}🔥 Creating and running PySpark ETL job...${NC}"
    
    # Create Dataproc cluster (smaller to fit quota)
    gcloud dataproc clusters create hospital-etl-cluster \
        --region=$REGION \
        --zone=$ZONE \
        --master-machine-type=n1-standard-2 \
        --master-boot-disk-size=50GB \
        --num-workers=1 \
        --worker-machine-type=n1-standard-2 \
        --worker-boot-disk-size=50GB \
        --image-version=2.1-debian11 \
        --optional-components=JUPYTER \
        --project=$PROJECT_ID
    
    # Submit PySpark job
    gcloud dataproc jobs submit pyspark \
        gs://$PROCESSED_BUCKET/scripts/run_etl.py \
        --cluster=hospital-etl-cluster \
        --region=$REGION \
        --project=$PROJECT_ID \
        -- \
        --project-id=$PROJECT_ID \
        --raw-bucket=$RAW_BUCKET \
        --dataset-id=$BIGQUERY_DATASET
    
    echo -e "${GREEN}🎉 PySpark ETL job completed!${NC}"
    echo ""
    
    # Test the results
    echo -e "${YELLOW}🧪 Testing the results...${NC}"
    
    # Check BigQuery tables
    echo "Checking BigQuery tables..."
    bq query --use_legacy_sql=false "SELECT COUNT(*) as patient_count FROM \`$PROJECT_ID.$BIGQUERY_DATASET.patients\`"
    bq query --use_legacy_sql=false "SELECT COUNT(*) as treatment_count FROM \`$PROJECT_ID.$BIGQUERY_DATASET.treatments\`"
    
    # Run sample analysis
    echo "Running sample analysis..."
    bq query --use_legacy_sql=false "
    SELECT 
        diagnosis,
        COUNT(*) as patient_count,
        AVG(length_of_stay_days) as avg_stay_days
    FROM \`$PROJECT_ID.$BIGQUERY_DATASET.patients\`
    GROUP BY diagnosis
    ORDER BY patient_count DESC
    LIMIT 10
    "
    
    echo -e "${GREEN}🎉 Deployment and ETL completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "1. Check BigQuery Console for processed data"
    echo "2. Run analysis queries on the data"
    echo "3. Clean up Dataproc cluster when done: gcloud dataproc clusters delete hospital-etl-cluster --region=$REGION"
    echo ""
    echo -e "${YELLOW}🔗 Useful Links:${NC}"
    echo "BigQuery Console: https://console.cloud.google.com/bigquery"
    echo "Cloud Storage: https://console.cloud.google.com/storage"
    echo "Dataproc Console: https://console.cloud.google.com/dataproc"
    
else
    echo -e "${YELLOW}❌ Deployment cancelled${NC}"
fi

echo -e "${GREEN}✨ Deployment script completed!${NC}"
