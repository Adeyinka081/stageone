# Use official Python slim image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Upgrade pip and install dependencies
RUN python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy all project files
COPY . .

# Detect which FastAPI file exists
# If main.py exists, run it; else if app.py exists, run it
CMD ["sh", "-c", "\
if [ -f main.py ]; then \
    uvicorn main:app --host 0.0.0.0 --port 5000; \
elif [ -f app.py ]; then \
    uvicorn app:app --host 0.0.0.0 --port 5000; \
else \
    echo 'Error: No FastAPI app found (main.py or app.py missing)' && exit 1; \
fi"]

