# 🔧 Fix GitHub Actions - Step by Step Guide

## ❌ Current Problem
The GitHub Actions are failing because the `GCP_SA_KEY` secret is not set up in your GitHub repository.

## ✅ Solution - Follow These Steps

### Step 1: Create Service Account and Get Key

Run this command in your terminal:

```bash
./setup-github-secrets.sh
```

This will:
- Create a service account in your GCP project
- Generate a JSON key file
- Show you exactly what to do next

### Step 2: Add Secret to GitHub

1. **Go to your GitHub repository**: https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP

2. **Navigate to Settings**:
   - Click on "Settings" tab
   - Click on "Secrets and variables" in the left sidebar
   - Click on "Actions"

3. **Add the Secret**:
   - Click "New repository secret"
   - Name: `GCP_SA_KEY`
   - Value: Copy the entire contents of `github-actions-key.json` file
   - Click "Add secret"

### Step 3: Test the Fix

After adding the secret, push any small change to trigger the workflow:

```bash
echo "# Test" >> README.md
git add README.md
git commit -m "Test GitHub Actions fix"
git push origin main
```

### Step 4: Verify Success

1. Go to the "Actions" tab in your GitHub repository
2. Check that the workflow runs successfully
3. All steps should show green checkmarks ✅

## 🚨 Alternative: Use Simple Workflow (No Secrets Required)

If you want to test without setting up secrets, I've created a simpler workflow:

1. **Rename the current workflow**:
   ```bash
   mv .github/workflows/deploy.yml .github/workflows/deploy-with-secrets.yml
   ```

2. **Use the simple workflow**:
   ```bash
   mv .github/workflows/deploy-simple.yml .github/workflows/deploy.yml
   ```

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Use simple workflow for testing"
   git push origin main
   ```

This simple workflow will:
- ✅ Validate Terraform (without GCP authentication)
- ⚠️ Skip deployment (requires secrets)
- ✅ Show you exactly what needs to be set up

## 🔍 Troubleshooting

### If the secret is still not working:

1. **Check the secret name**: Must be exactly `GCP_SA_KEY`
2. **Check the secret value**: Must be valid JSON
3. **Check the repository**: Make sure you're in the right repository
4. **Check permissions**: Make sure the service account has the right roles

### If you get "secret not found" error:

The secret might not be available to the workflow. Try:

1. **Recreate the secret** with a different name
2. **Check repository settings** - make sure secrets are enabled
3. **Use environment secrets** instead of repository secrets

## 📋 Quick Commands

```bash
# 1. Set up service account
./setup-github-secrets.sh

# 2. Test locally
./test-github-actions.sh

# 3. Check secret content
cat github-actions-key.json

# 4. Push changes
git add .
git commit -m "Fix GitHub Actions"
git push origin main
```

## 🎯 Expected Result

After following these steps, your GitHub Actions should:

1. ✅ **Validate Terraform** - Pass with green checkmark
2. ✅ **Deploy Infrastructure** - Create GCP resources
3. ✅ **Run ETL Pipeline** - Process data with PySpark
4. ✅ **Notify Success** - Show completion message

## 📞 Need Help?

If you're still having issues:

1. **Check the Actions tab** for detailed error messages
2. **Run the test script** to verify local setup
3. **Check the service account** has the right permissions
4. **Verify the secret** is properly formatted JSON

The key issue is that GitHub Actions needs the `GCP_SA_KEY` secret to authenticate with Google Cloud. Once that's set up, everything will work perfectly!
