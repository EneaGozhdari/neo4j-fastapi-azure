# Slim, single-stage image for a tiny FastAPI service.
FROM python:3.12-slim

# Predictable Python behaviour in containers.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install dependencies first so this layer is cached across code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code.
COPY main.py .

# Run as a non-root user.
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 8000

# Configuration (NEO4J_URI/USER/PASSWORD) is supplied at runtime via env vars.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
