FROM --platform=linux/amd64 rockylinux:9

# Install dependencies
RUN dnf install -y tar shadow-utils && dnf clean all

# Copy pre-downloaded Ollama tarball from assets
COPY assets/ollama.tar.gz /tmp/

# Extract Ollama binary and libraries
RUN tar -xf /tmp/ollama.tar.gz -C /usr/local && \
    chmod +x /usr/local/bin/ollama

# Create ollama user and models directory
RUN useradd -m ollama
RUN mkdir -p /home/ollama/.ollama/models && chown -R ollama:ollama /home/ollama

# Copy and extract pre-downloaded models
COPY assets/ollama-models.tar.gz /tmp/
RUN cd /tmp && \
    tar -xzf ollama-models.tar.gz && \
    ls -la && \
    if [ -d ".ollama/models" ]; then \
        cp -r .ollama/models/* /home/ollama/.ollama/models/; \
    elif [ -d "models" ]; then \
        cp -r models/* /home/ollama/.ollama/models/; \
    else \
        find . -name "*.gguf" -o -name "sha256-*" | head -1 | xargs -I {} dirname {} | xargs -I {} cp -r {} /home/ollama/.ollama/models/; \
    fi && \
    chown -R ollama:ollama /home/ollama/.ollama && \
    rm -rf /tmp/ollama-models.tar.gz /tmp/.ollama /tmp/models

ENV HOME=/home/ollama
ENV OLLAMA_MODELS=/home/ollama/.ollama/models

USER ollama
WORKDIR /home/ollama

EXPOSE 11434

CMD ["ollama", "serve"]