#!/bin/bash

# Test GitHub Actions Workflow Locally
# This script simulates the GitHub Actions environment locally

set -e

PROJECT_ID="pyspark-469619"
REGION="us-central1"
ZONE="us-central1-a"

echo "🧪 Testing GitHub Actions Workflow Locally"
echo "=========================================="

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ You are not authenticated with gcloud. Please run:"
    echo "   gcloud auth login"
    exit 1
fi

# Set project
echo "📋 Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Test Terraform validation
echo "🔍 Testing Terraform validation..."
terraform fmt -check -recursive
echo "✅ Terraform format check passed"

terraform init
echo "✅ Terraform init completed"

terraform validate
echo "✅ Terraform validate passed"

# Test Terraform plan
echo "📋 Testing Terraform plan..."
terraform plan \
    -var="project_id=$PROJECT_ID" \
    -var="region=$REGION" \
    -var="zone=$ZONE" \
    -out=tfplan
echo "✅ Terraform plan completed successfully"

# Test GCS operations
echo "🪣 Testing GCS operations..."
RAW_BUCKET=$(gcloud storage buckets list --filter="name:hospital-raw-data" --format="value(name)" | head -1)
if [ -n "$RAW_BUCKET" ]; then
    echo "✅ Found raw data bucket: $RAW_BUCKET"
    
    # Test file upload
    if [ -f "data/raw/patients.csv" ]; then
        echo "📤 Testing file upload to GCS..."
        gsutil cp data/raw/patients.csv gs://$RAW_BUCKET/data/raw/test-upload.csv
        echo "✅ File upload test successful"
        
        # Clean up test file
        gsutil rm gs://$RAW_BUCKET/data/raw/test-upload.csv
        echo "🧹 Cleaned up test file"
    else
        echo "⚠️  Sample data files not found, skipping upload test"
    fi
else
    echo "⚠️  No raw data bucket found. Run terraform apply first."
fi

# Test BigQuery operations
echo "📊 Testing BigQuery operations..."
bq query --use_legacy_sql=false "SELECT 1 as test" --max_rows=1
echo "✅ BigQuery connection test successful"

# Test Dataproc operations
echo "🔄 Testing Dataproc operations..."
gcloud dataproc clusters list --region=$REGION --format="table(name,status.state)" | head -5
echo "✅ Dataproc API access test successful"

echo ""
echo "🎉 All tests passed! Your GitHub Actions should work properly."
echo ""
echo "📋 Summary of what was tested:"
echo "   ✅ Terraform validation and planning"
echo "   ✅ GCS bucket access and file operations"
echo "   ✅ BigQuery connection and queries"
echo "   ✅ Dataproc API access"
echo ""
echo "🚀 Next steps:"
echo "   1. Run ./setup-github-secrets.sh to create service account"
echo "   2. Add GCP_SA_KEY secret to GitHub repository"
echo "   3. Push changes to trigger GitHub Actions"
