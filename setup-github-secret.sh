#!/bin/bash

# Complete GitHub Secret Setup Script
# This script will help you set up the GCP_SA_KEY secret correctly

echo "🔧 Complete GitHub Secret Setup"
echo "==============================="

# Check if key file exists
if [ ! -f "github-actions-key.json" ]; then
    echo "❌ github-actions-key.json not found!"
    echo "Run ./setup-github-secrets.sh first"
    exit 1
fi

echo "✅ Service account key found"

# Display the key content
echo ""
echo "📋 Copy this ENTIRE JSON content:"
echo "================================="
cat github-actions-key.json
echo ""
echo "================================="

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo ""
echo "1. Go to: https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/settings/secrets/actions"
echo ""
echo "2. Click 'New repository secret'"
echo ""
echo "3. Fill in:"
echo "   Name: GCP_SA_KEY"
echo "   Value: [Paste the JSON content above]"
echo ""
echo "4. Click 'Add secret'"
echo ""
echo "5. Test by pushing a change:"
echo "   echo '# Test' >> README.md"
echo "   git add . && git commit -m 'Test' && git push"
echo ""
echo "✅ After adding the secret, your GitHub Actions will work perfectly!"
