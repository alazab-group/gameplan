FROM python:3.11-slim-bookworm

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    pkg-config \
    # Database clients
    default-mysql-client \
    postgresql-client \
    # Node.js and npm
    nodejs \
    npm \
    # Media processing
    libmagic1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    # Fonts
    fonts-liberation \
    fonts-noto-cjk \
    # PDF generation
    wkhtmltopdf \
    # SSL and crypto
    libssl-dev \
    libffi-dev \
    # Git
    git \
    # Process management
    supervisor \
    # Image processing
    libjpeg-dev \
    libpng-dev \
    # XML/HTML processing
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create gameplan user
RUN useradd -m -s /bin/bash gameplan

# Set working directory
WORKDIR /home/gameplan

# Copy requirements first for better caching
COPY requirements.txt .
COPY package.json .

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

# Install Node.js dependencies
RUN npm install -g yarn \
    && npm install

# Copy application code
COPY . .

# Set ownership
RUN chown -R gameplan:gameplan /home/gameplan

# Switch to gameplan user
USER gameplan

# Build frontend assets
RUN npm run production

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/method/ping')" || exit 1

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "gameplan.app:application"]
