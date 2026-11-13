FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create and switch to an unprivileged runtime user (S-07)
RUN useradd -m -u 10001 appuser && chown -R appuser:appuser /app
USER appuser

# Run uvicorn server on port 8080 (Cloud Run default)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
