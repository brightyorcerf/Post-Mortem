FROM python:3.11-slim

# ── System deps ──────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Working directory ─────────────────────────────────────────────────────────
WORKDIR /app

# ── Python dependencies ───────────────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── HF Spaces runs as a non-root user (UID 1000) ─────────────────────────────
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# ── Application source (single authoritative copy) ───────────────────────────
WORKDIR $HOME/app
COPY --chown=user . $HOME/app

# ── Port (HF Spaces expects 7860) ────────────────────────────────────────────
ENV PORT=7860
EXPOSE 7860

# ── Health check ──────────────────────────────────────────────────────────────
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:${PORT}/ping || exit 1

# ── Entrypoint ────────────────────────────────────────────────────────────────
CMD ["python", "-m", "server.app"]