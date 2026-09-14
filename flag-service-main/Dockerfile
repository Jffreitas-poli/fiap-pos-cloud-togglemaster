# Stage 1: Build stage (installs compilation tools)
FROM python:3.11-alpine AS builder

WORKDIR /app

# Install temporary build dependencies needed to compile psycopg2
RUN apk add --no-cache gcc musl-dev postgresql-dev python3-dev

COPY requirements.txt .

# Install dependencies to an isolated folder
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Final runtime stage (clean and secure)
FROM python:3.11-alpine

WORKDIR /app

# Copy the pre-compiled Python environments from the builder stage
COPY --from=builder /install /usr/local

# Install ONLY the lightweight runtime C-dependency required by psycopg2
RUN apk add --no-cache libpq

COPY app.py .

CMD ["python", "app.py"]