# 🚀 CI/CD Setup for Hospital ETL Pipeline

This document explains the GitHub Actions CI/CD workflows for the Hospital ETL Pipeline.

## 📋 Workflows Overview

### 1. **Deploy Workflow** (`.github/workflows/deploy.yml`)
**Triggers:** Push to `main`, Pull Requests, Manual dispatch

**Jobs:**
- **Validate Terraform**: Checks Terraform syntax and formatting
- **Deploy Infrastructure**: Creates GCP resources using Terraform
- **Run ETL Pipeline**: Executes PySpark ETL job on Dataproc
- **Notify Success**: Sends success notifications

### 2. **Test Workflow** (`.github/workflows/test.yml`)
**Triggers:** Push to `main`/`develop`, Pull Requests, Manual dispatch

**Jobs:**
- **Data Quality Check**: Validates CSV data quality
- **Validate Schemas**: Checks BigQuery JSON schemas
- **Test PySpark Script**: Validates Python syntax
- **Security Scan**: Runs Trivy vulnerability scanner
- **Notify Test Results**: Reports test outcomes

### 3. **Scheduled ETL** (`.github/workflows/scheduled-etl.yml`)
**Triggers:** Daily at 2 AM UTC, Manual dispatch

**Jobs:**
- **Scheduled ETL**: Runs daily ETL pipeline
- **Generate Reports**: Creates ETL execution reports
- **Cleanup**: Removes temporary resources

## 🔧 Required GitHub Secrets

To use these workflows, you need to set up the following secrets in your GitHub repository:

### 1. **GCP_SA_KEY**
- **Description**: Google Cloud Service Account JSON key
- **How to create**:
  ```bash
  # Create a service account
  gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=pyspark-469619

  # Grant necessary roles
  gcloud projects add-iam-policy-binding pyspark-469619 \
    --member="serviceAccount:github-actions-sa@pyspark-469619.iam.gserviceaccount.com" \
    --role="roles/editor"

  # Create and download key
  gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@pyspark-469619.iam.gserviceaccount.com

  # Copy the contents of github-actions-key.json to GitHub Secrets
  ```

### 2. **Set up GitHub Secrets**
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add `GCP_SA_KEY` with the JSON key content

## 🚀 How to Use

### **Automatic Deployment**
- Push to `main` branch triggers full deployment
- Pull requests trigger validation only
- Use "Actions" tab to manually trigger workflows

### **Manual Deployment**
1. Go to **Actions** tab in GitHub
2. Select **Deploy Hospital ETL Pipeline**
3. Click **Run workflow**
4. Choose branch and click **Run workflow**

### **Monitoring**
- Check **Actions** tab for workflow status
- View logs for detailed execution information
- ETL reports are stored in GCS bucket

## 📊 Workflow Status Badges

Add these badges to your README:

```markdown
![Deploy](https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/workflows/Deploy%20Hospital%20ETL%20Pipeline/badge.svg)
![Test](https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/workflows/Test%20and%20Quality%20Checks/badge.svg)
![Scheduled ETL](https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/workflows/Scheduled%20ETL%20Pipeline/badge.svg)
```

## 🔍 Troubleshooting

### **Common Issues:**

1. **Authentication Failed**
   - Verify `GCP_SA_KEY` secret is correctly set
   - Check service account has required permissions

2. **Terraform Apply Failed**
   - Check GCP project quotas
   - Verify APIs are enabled

3. **Dataproc Job Failed**
   - Check PySpark script syntax
   - Verify data files exist in GCS

4. **BigQuery Access Denied**
   - Ensure service account has BigQuery permissions
   - Check dataset and table permissions

### **Debug Steps:**
1. Check workflow logs in GitHub Actions
2. Verify GCP resources in Console
3. Test locally with `gcloud` commands
4. Check BigQuery for data loading issues

## 📈 Monitoring and Alerts

### **Success Metrics:**
- All workflows complete successfully
- Data loaded to BigQuery without errors
- No security vulnerabilities detected

### **Failure Alerts:**
- Workflow failures send notifications
- ETL reports track execution status
- Security scans flag vulnerabilities

## 🔄 Customization

### **Modify Schedule:**
Edit `.github/workflows/scheduled-etl.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # Change to your preferred time
```

### **Add Notifications:**
Add Slack/Email notifications in workflow steps:
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### **Environment Variables:**
Add custom environment variables in workflow files:
```yaml
env:
  CUSTOM_VAR: value
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Cloud GitHub Actions](https://github.com/google-github-actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)

---

**🎉 Your Hospital ETL Pipeline now has full CI/CD automation!**
