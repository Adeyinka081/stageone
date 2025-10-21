# Use official Python image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements if exists
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt || echo "No requirements.txt found, skipping"

# Copy the rest of the project
COPY . .

# Expose the internal application port
EXPOSE 5000

# Command to run your app (adjust if different)
CMD ["python", "app.py"]

