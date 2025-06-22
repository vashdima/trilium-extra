FROM --platform=linux/amd64 rockylinux:9

# Install dependencies
RUN dnf install -y tar unzip shadow-utils && dnf clean all

# Copy pre-downloaded Ollama tarball from assets
COPY assets/ollama.tar.gz /tmp/

# Extract Ollama binary and libraries
RUN tar -xf /tmp/ollama.tar.gz -C /usr/local && \
    chmod +x /usr/local/bin/ollama

# Create ollama user and models directory
RUN useradd -m ollama
RUN mkdir -p /home/ollama/.ollama/models && chown -R ollama:ollama /home/ollama

# Copy and extract pre-downloaded models
COPY assets/ollama-models.zip /tmp/
RUN cd /tmp && \
    unzip ollama-models.zip && \
    mv .ollama/models/* /home/ollama/.ollama/models/ && \
    chown -R ollama:ollama /home/ollama/.ollama && \
    rm -rf /tmp/ollama-models.zip /tmp/.ollama

ENV HOME=/home/ollama
ENV OLLAMA_MODELS=/home/ollama/.ollama/models

USER ollama
WORKDIR /home/ollama

EXPOSE 11434

CMD ["ollama", "serve"]