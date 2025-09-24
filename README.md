# 🏥 Hospital Data ETL Pipeline with PySpark

A complete **PySpark-based ETL pipeline** for processing hospital data on Google Cloud Platform.

## 🚀 Quick Start

### Prerequisites
- Google Cloud SDK (`gcloud`) installed
- Terraform installed
- Python 3.7+ (for local development)

### Option 1: Local Deployment (Recommended)
```bash
# Make the deployment script executable
chmod +x deploy_pyspark.sh

# Deploy the entire pipeline
./deploy_pyspark.sh
```

### Option 2: CI/CD Validation
- **GitHub Actions** automatically validates code quality, Terraform configuration, and data files
- **No ETL execution** in CI/CD (avoids memory issues)
- **Manual ETL** runs locally when needed

### Option 3: GitHub Setup
```bash
# Set up GitHub Actions (one-time setup)
chmod +x setup-github-secrets.sh
./setup-github-secrets.sh
```

## 📊 What This Does

1. **Infrastructure Setup**:
   - Creates GCS buckets for raw and processed data
   - Sets up BigQuery dataset and tables (patients, treatments, hospital_analysis)
   - Configures service accounts with proper permissions

2. **Data Processing**:
   - Reads patient, treatment, and hospital analysis data from CSV files
   - Performs comprehensive data validation and cleaning
   - Transforms and enriches the data with business logic
   - Loads processed data into BigQuery tables

3. **Data Analysis**:
   - Provides sample queries for data analysis
   - Shows data quality metrics and insights
   - Enables business intelligence and healthcare analytics
   - Supports 1000+ patient records with complete analysis

## 📁 Project Structure

```
├── data/
│   └── raw/
│       ├── patients.csv              # Sample patient data (50 records)
│       ├── treatments.csv            # Sample treatment data (100 records)
│       └── hospital data analysis.csv # Hospital analysis data (1000 records)
├── schemas/
│   ├── patient_schema.json           # BigQuery schema for patients
│   ├── treatment_schema.json         # BigQuery schema for treatments
│   └── hospital_analysis_schema.json # BigQuery schema for hospital analysis
├── .github/workflows/
│   ├── validate.yml                  # CI/CD validation workflow
│   ├── test.yml                      # Quality checks workflow
│   └── deploy.yml                    # ETL deployment (disabled)
├── main.tf                           # Terraform infrastructure
├── variables.tf                      # Terraform variables
├── run_etl.py                       # PySpark ETL script
├── deploy_pyspark.sh                # Local deployment script
├── setup-github-secrets.sh          # GitHub Actions setup
├── requirements.txt                  # Python dependencies
├── README.md                        # This file
├── Hospital_ETL_Project_Documentation.md    # Detailed documentation
├── Hospital_ETL_Project_Documentation.docx  # Word documentation
└── CI-CD-SETUP.md                   # CI/CD setup instructions
```

## 🔧 Configuration

The project is configured for:
- **Project ID**: `pyspark-469619`
- **Region**: `us-central1`
- **Zone**: `us-central1-a`

## 📈 Sample Queries

After running the ETL pipeline, you can query your data in BigQuery:

### Patient Data
```sql
-- Count patients by diagnosis
SELECT diagnosis, COUNT(*) as patient_count
FROM `pyspark-469619.hospital_data.patients`
GROUP BY diagnosis
ORDER BY patient_count DESC;

-- Average treatment cost by type
SELECT treatment_type, AVG(cost) as avg_cost
FROM `pyspark-469619.hospital_data.treatments`
GROUP BY treatment_type
ORDER BY avg_cost DESC;
```

### Hospital Analysis Data
```sql
-- Top medical conditions by patient count
SELECT condition, COUNT(*) as patient_count, AVG(cost) as avg_cost
FROM `pyspark-469619.hospital_data.hospital_analysis`
GROUP BY condition
ORDER BY patient_count DESC
LIMIT 10;

-- Cost analysis by age groups
SELECT 
  CASE 
    WHEN age < 30 THEN 'Under 30'
    WHEN age < 50 THEN '30-49'
    WHEN age < 70 THEN '50-69'
    ELSE '70+'
  END as age_group,
  COUNT(*) as patients,
  AVG(cost) as avg_cost,
  AVG(satisfaction) as avg_satisfaction
FROM `pyspark-469619.hospital_data.hospital_analysis`
GROUP BY age_group
ORDER BY avg_cost DESC;

-- Readmission analysis
SELECT 
  readmission,
  COUNT(*) as patient_count,
  AVG(cost) as avg_cost,
  AVG(length_of_stay) as avg_stay
FROM `pyspark-469619.hospital_data.hospital_analysis`
GROUP BY readmission;
```

## 🧹 Cleanup

To remove all resources and stop billing:
```bash
terraform destroy -auto-approve
```

## 💡 Features

- ✅ **PySpark-based processing** for scalability
- ✅ **Data validation** and quality checks
- ✅ **Schema enforcement** in BigQuery
- ✅ **Cost-optimized** infrastructure
- ✅ **Automated deployment** with Terraform
- ✅ **Sample data** included for testing
- ✅ **CI/CD Pipeline** with GitHub Actions (validation only)
- ✅ **Automated testing** and quality checks
- ✅ **Local ETL execution** with full resources
- ✅ **Security scanning** and monitoring
- ✅ **Clean project structure** (no unwanted files)
- ✅ **Comprehensive documentation** (Markdown + Word)

## 🚀 CI/CD Pipeline

This project includes automated CI/CD workflows:

- **✅ Validate Project**: Code quality, Terraform validation, data validation
- **✅ Test and Quality Checks**: Python linting, formatting, security scanning
- **❌ Deploy Hospital ETL Pipeline**: Disabled (causes memory issues in CI/CD)

### 🎯 Current Status
- **CI/CD**: ✅ **PASSING** - Fast validation and quality checks
- **ETL Pipeline**: 🏠 **Local Only** - Run with `./deploy_pyspark.sh`

See [CI-CD-SETUP.md](CI-CD-SETUP.md) for detailed setup instructions.

## 🔄 CI/CD Strategy

### ✅ What Works in CI/CD
- **Code Validation**: Python linting, formatting, and syntax checks
- **Terraform Validation**: Infrastructure configuration validation
- **Data Validation**: CSV file structure and content validation
- **Security Scanning**: Basic security checks

### 🏠 What Runs Locally
- **ETL Pipeline**: Full PySpark ETL execution (requires more memory)
- **Dataproc Clusters**: Resource-intensive operations
- **BigQuery Data Loading**: Large-scale data processing

### 🎯 Why This Approach?
- **Reliability**: CI/CD always passes (no memory issues)
- **Speed**: Fast validation and feedback
- **Flexibility**: Run ETL when needed with full resources
- **Cost-Effective**: No expensive cloud resources in CI/CD

## 🔗 Useful Links

- [BigQuery Console](https://console.cloud.google.com/bigquery)
- [Cloud Storage Console](https://console.cloud.google.com/storage)
- [Dataproc Console](https://console.cloud.google.com/dataproc)
- [GitHub Actions](https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/actions)

---

**Built with ❤️ using PySpark, BigQuery, Google Cloud Platform, and GitHub Actions**
