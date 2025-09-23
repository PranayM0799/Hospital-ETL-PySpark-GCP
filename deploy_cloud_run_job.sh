#!/bin/bash

# Hospital ETL Pipeline - Cloud Run Jobs Deployment
# Simple, reliable batch processing without Dataproc complexity

set -e

PROJECT_ID="pyspark-469619"
REGION="us-central1"
JOB_NAME="hospital-etl-job"
RAW_BUCKET="hospital-raw-data-685c9129"
DATASET_ID="hospital_data"

echo "🚀 Deploying Hospital ETL Pipeline with Cloud Run Jobs..."

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📋 Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Upload data to GCS (if not already there)
echo "📤 Uploading data to GCS..."
gsutil cp data/raw/patients.csv gs://$RAW_BUCKET/data/raw/ || echo "Patients data already exists"
gsutil cp data/raw/treatments.csv gs://$RAW_BUCKET/data/raw/ || echo "Treatments data already exists"
gsutil cp "data/raw/hospital data analysis.csv" gs://$RAW_BUCKET/data/raw/ || echo "Hospital analysis data already exists"

# Create requirements.txt
echo "📦 Creating requirements.txt..."
cat > requirements.txt << EOF
google-cloud-storage==2.10.0
google-cloud-bigquery==3.11.4
pandas==2.0.3
EOF

# Create Dockerfile for Cloud Run Jobs
echo "🐳 Creating Dockerfile..."
cat > Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY etl_cloud_run.py .

CMD ["python", "etl_cloud_run.py"]
EOF

# Build the container
echo "🏗️ Building container..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$JOB_NAME .

# Create Cloud Run Job
echo "🚀 Creating Cloud Run Job..."
gcloud run jobs create $JOB_NAME \
  --image gcr.io/$PROJECT_ID/$JOB_NAME \
  --region $REGION \
  --memory 2Gi \
  --cpu 2 \
  --timeout 3600 \
  --set-env-vars PROJECT_ID=$PROJECT_ID,RAW_BUCKET=$RAW_BUCKET,DATASET_ID=$DATASET_ID \
  --service-account=dataproc-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --max-retries 1

echo "✅ Cloud Run Job created successfully!"

# Execute the ETL job
echo "🔄 Executing ETL job..."
gcloud run jobs execute $JOB_NAME --region $REGION --wait

echo "✅ ETL Pipeline completed successfully!"
echo "📊 Check your BigQuery dataset: $PROJECT_ID.$DATASET_ID"

# Cleanup
echo "🧹 Cleaning up..."
rm -f requirements.txt Dockerfile

echo "🎉 Deployment complete!"
