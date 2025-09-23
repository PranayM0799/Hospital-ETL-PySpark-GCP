#!/bin/bash

# Verify GitHub Secret Setup
# This script helps you verify that the GCP_SA_KEY secret is set up correctly

echo "🔍 Verifying GitHub Secret Setup"
echo "================================"

# Check if the key file exists
if [ ! -f "github-actions-key.json" ]; then
    echo "❌ github-actions-key.json not found!"
    echo "Run ./setup-github-secrets.sh first"
    exit 1
fi

echo "✅ github-actions-key.json found"

# Check if the key file is valid JSON
if ! jq empty github-actions-key.json 2>/dev/null; then
    echo "❌ github-actions-key.json is not valid JSON!"
    exit 1
fi

echo "✅ github-actions-key.json is valid JSON"

# Extract key information
PROJECT_ID=$(jq -r '.project_id' github-actions-key.json)
CLIENT_EMAIL=$(jq -r '.client_email' github-actions-key.json)
KEY_ID=$(jq -r '.private_key_id' github-actions-key.json)

echo "📋 Key Information:"
echo "   Project ID: $PROJECT_ID"
echo "   Client Email: $CLIENT_EMAIL"
echo "   Key ID: $KEY_ID"

# Check if the service account exists in GCP
echo ""
echo "🔍 Checking service account in GCP..."

if gcloud iam service-accounts describe $CLIENT_EMAIL &> /dev/null; then
    echo "✅ Service account exists in GCP"
else
    echo "❌ Service account not found in GCP"
    echo "Run ./setup-github-secrets.sh to create it"
    exit 1
fi

# Test the key locally
echo ""
echo "🧪 Testing the key locally..."

export GOOGLE_APPLICATION_CREDENTIALS="github-actions-key.json"

if gcloud auth activate-service-account --key-file=github-actions-key.json; then
    echo "✅ Key authentication successful"
    
    # Test basic GCP operations
    if gcloud config set project $PROJECT_ID; then
        echo "✅ Project configuration successful"
    fi
    
    if gcloud storage buckets list --limit=1 &> /dev/null; then
        echo "✅ GCS access successful"
    fi
    
    if bq query --use_legacy_sql=false "SELECT 1" --max_rows=1 &> /dev/null; then
        echo "✅ BigQuery access successful"
    fi
    
else
    echo "❌ Key authentication failed"
    exit 1
fi

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo ""
echo "1. Copy the ENTIRE contents of github-actions-key.json"
echo "2. Go to: https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/settings/secrets/actions"
echo "3. Click 'New repository secret'"
echo "4. Name: GCP_SA_KEY"
echo "5. Value: Paste the JSON content"
echo "6. Click 'Add secret'"
echo ""
echo "📋 To copy the key content, run:"
echo "   cat github-actions-key.json"
echo ""
echo "🧪 After adding the secret, test with:"
echo "   echo '# Test' >> README.md && git add . && git commit -m 'Test' && git push"
