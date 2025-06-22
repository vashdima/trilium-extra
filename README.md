 # Ollama Custom Docker Setup

This setup provides a containerized Ollama service with pre-loaded models, optimized for different architectures.

## Architecture Compatibility

✅ **Your ollama binary is Linux x86-64**, which means:
- **Intel NUC (x86-64)**: Native performance, no emulation needed
- **Apple Silicon**: Requires platform emulation (slower but functional)

## Quick Start

### For Intel x86-64 Systems (Intel NUC, etc.)
```bash
# Use the Intel-optimized configuration
docker-compose -f docker-compose.intel.yml up -d
```

### For Apple Silicon (M1/M2/M3 Macs)
```bash
# Use the Apple Silicon configuration with emulation
docker-compose -f docker-compose.apple.yml up -d
```

### Generic (Auto-detect)
```bash
# Use the standard configuration
docker-compose up -d
```

## Building the Image

1. **Download and combine assets** (only needed once):
```bash
make all
```

2. **Build the Docker image**:

For Intel x86-64:
```bash
docker build -t ollama-custom .
```

For Apple Silicon (with emulation):
```bash
docker build --platform linux/amd64 -t ollama-custom .
```

## Performance Expectations

### Intel NUC (Native x86-64)
- ✅ **Best performance** - native execution
- ✅ **Lower CPU usage**
- ✅ **Intel GPU acceleration** (if enabled)
- ✅ **No emulation overhead**

### Apple Silicon (Emulated)
- ⚠️ **Slower performance** - requires emulation
- ⚠️ **Higher CPU usage**
- ⚠️ **No GPU acceleration**
- ✅ **Still functional** for development/testing

## Testing

```bash
# Check if service is running
curl http://localhost:11434/api/tags

# Test embedding generation
curl -X POST http://localhost:11434/api/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "nomic-embed-text", "prompt": "Hello world"}'
```

## Configuration Files

- `docker-compose.yml` - Generic configuration
- `docker-compose.intel.yml` - Optimized for Intel x86-64
- `docker-compose.apple.yml` - Optimized for Apple Silicon
- `Dockerfile` - Container build configuration
- `Makefile` - Asset download and preparation

## Included Models

- **nomic-embed-text:latest** (137M parameters, F16 quantization)
  - Text embedding model
  - 768-dimensional embeddings
  - Vocabulary: 30,522 tokens

## Intel NUC Optimization

The Intel configuration includes:
- Intel GPU device access (`/dev/dri`)
- Optimized parallel processing settings
- Memory resource limits
- No platform emulation overhead

## Commands

```bash
# Start service
docker-compose -f docker-compose.intel.yml up -d

# Stop service
docker-compose -f docker-compose.intel.yml down

# View logs
docker-compose -f docker-compose.intel.yml logs -f

# Check status
docker-compose -f docker-compose.intel.yml ps

# Restart service
docker-compose -f docker-compose.intel.yml restart
```

## Troubleshooting

### Apple Silicon Issues
- Make sure Docker Desktop is set to use Rosetta for x86/amd64 emulation
- Build with `--platform linux/amd64` flag
- Use the Apple Silicon specific compose file

### Intel NUC Issues
- Ensure Docker daemon is running
- Check if `/dev/dri` exists for GPU acceleration
- Verify ollama models are properly loaded in logs

## Asset Management

The Makefile handles downloading and combining split files:
- Downloads `ollama_part_*` files from GitHub releases
- Downloads `ollama-models-part-*` files
- Combines them into `ollama.tar.gz` and `ollama-models.zip`
- Skips downloads if target files already exist 
