FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY etl_cloud_run.py .

CMD ["python", "etl_cloud_run.py"]
