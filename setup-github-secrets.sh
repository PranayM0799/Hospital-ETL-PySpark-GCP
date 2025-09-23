#!/bin/bash

# Setup GitHub Secrets for Hospital ETL Pipeline
# This script creates a service account and provides instructions for setting up GitHub secrets

set -e

PROJECT_ID="pyspark-469619"
SERVICE_ACCOUNT_NAME="github-actions-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="github-actions-key.json"

echo "🔧 Setting up GitHub Actions Service Account for Hospital ETL Pipeline"
echo "=================================================================="

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ You are not authenticated with gcloud. Please run:"
    echo "   gcloud auth login"
    exit 1
fi

# Set the project
echo "📋 Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Check if service account already exists
if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &> /dev/null; then
    echo "⚠️  Service account $SERVICE_ACCOUNT_EMAIL already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing service account..."
        gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL --quiet
    else
        echo "ℹ️  Using existing service account"
    fi
fi

# Create service account if it doesn't exist
if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &> /dev/null; then
    echo "👤 Creating service account: $SERVICE_ACCOUNT_NAME"
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Service Account for Hospital ETL" \
        --description="Service account for GitHub Actions CI/CD pipeline" \
        --project=$PROJECT_ID
fi

# Grant necessary roles
echo "🔐 Granting necessary roles to service account..."

ROLES=(
    "roles/editor"
    "roles/bigquery.admin"
    "roles/storage.admin"
    "roles/dataproc.admin"
    "roles/iam.serviceAccountUser"
)

for role in "${ROLES[@]}"; do
    echo "   - Granting $role"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --quiet
done

# Create and download key
echo "🔑 Creating service account key..."
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT_EMAIL \
    --project=$PROJECT_ID

echo ""
echo "✅ Service account setup complete!"
echo ""
echo "📋 Next steps to set up GitHub Secrets:"
echo "======================================="
echo ""
echo "1. Go to your GitHub repository:"
echo "   https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP"
echo ""
echo "2. Navigate to: Settings → Secrets and variables → Actions"
echo ""
echo "3. Click 'New repository secret'"
echo ""
echo "4. Add the following secret:"
echo "   Name: GCP_SA_KEY"
echo "   Value: (copy the contents of $KEY_FILE)"
echo ""
echo "5. To copy the key content, run:"
echo "   cat $KEY_FILE"
echo ""
echo "6. Click 'Add secret'"
echo ""
echo "🔒 Security Note:"
echo "   - Keep the $KEY_FILE secure and don't commit it to git"
echo "   - The key is already added to .gitignore"
echo "   - You can delete the key file after setting up the secret"
echo ""
echo "🧪 Test the setup:"
echo "   - Push a change to trigger the GitHub Actions workflow"
echo "   - Check the Actions tab for successful execution"
echo ""

# Add key file to gitignore if not already there
if ! grep -q "$KEY_FILE" .gitignore 2>/dev/null; then
    echo "$KEY_FILE" >> .gitignore
    echo "📝 Added $KEY_FILE to .gitignore"
fi

echo "🎉 Setup complete! Your GitHub Actions should now work properly."
