# 🏥 Hospital Data ETL Pipeline with PySpark

A complete **PySpark-based ETL pipeline** for processing hospital data on Google Cloud Platform.

## 🚀 Quick Start

### Prerequisites
- Google Cloud SDK (`gcloud`) installed
- Terraform installed
- Python 3.7+ (for local development)

### Deploy and Run
```bash
# Make the deployment script executable
chmod +x deploy_pyspark.sh

# Deploy the entire pipeline
./deploy_pyspark.sh
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
├── analysis/
│   └── hospital_insights.py          # Comprehensive analysis script
├── main.tf                           # Terraform infrastructure
├── variables.tf                      # Terraform variables
├── run_etl.py                       # PySpark ETL script
├── deploy_pyspark.sh                # Deployment script
├── data_quality_check.py            # Data quality analysis
└── README.md                        # This file
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
- ✅ **CI/CD Pipeline** with GitHub Actions
- ✅ **Automated testing** and quality checks
- ✅ **Scheduled ETL** runs daily
- ✅ **Security scanning** and monitoring

## 🚀 CI/CD Pipeline

This project includes automated CI/CD workflows:

- **🔄 Deploy**: Automatic deployment on push to main
- **🧪 Test**: Data quality checks and validation
- **⏰ Scheduled**: Daily ETL runs at 2 AM UTC
- **🔒 Security**: Automated vulnerability scanning

See [CI-CD-SETUP.md](CI-CD-SETUP.md) for detailed setup instructions.

## 🔗 Useful Links

- [BigQuery Console](https://console.cloud.google.com/bigquery)
- [Cloud Storage Console](https://console.cloud.google.com/storage)
- [Dataproc Console](https://console.cloud.google.com/dataproc)
- [GitHub Actions](https://github.com/PranayM0799/Hospital-ETL-PySpark-GCP/actions)

---

**Built with ❤️ using PySpark, BigQuery, Google Cloud Platform, and GitHub Actions**