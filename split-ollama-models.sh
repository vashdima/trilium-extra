#!/bin/bash

# Script to archive and split ~/.ollama/models/ into GitHub-friendly parts
# Usage: ./split-ollama-models.sh [options]

set -e  # Exit on any error

# Configuration
MODELS_DIR="$HOME/.ollama/models"
OUTPUT_DIR="$(pwd)"
ARCHIVE_NAME="ollama-models"
SPLIT_SIZE="90M"  # Slightly under 100MB to be safe
COMPRESS_LEVEL="6"  # Balance between compression and speed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << 'USAGE_EOF'
Usage: ./split-ollama-models.sh [OPTIONS]

Archive and split ~/.ollama/models/ into parts smaller than 100MB

OPTIONS:
    -s, --size SIZE      Split size (default: 90M)
    -o, --output DIR     Output directory (default: current directory)
    -n, --name NAME      Archive base name (default: ollama-models)
    -c, --compress LEVEL Compression level 1-9 (default: 6)
    -k, --keep          Keep original archive after splitting
    -q, --quiet         Quiet mode - minimal output
    -h, --help          Show this help message

EXAMPLES:
    ./split-ollama-models.sh                    # Use defaults
    ./split-ollama-models.sh -s 50M -o ~/uploads    # 50MB parts in ~/uploads
    ./split-ollama-models.sh -n my-models -k         # Custom name, keep archive
    ./split-ollama-models.sh --quiet                 # Minimal output

USAGE_EOF
}

# Parse command line arguments
KEEP_ARCHIVE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--size)
            SPLIT_SIZE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            ARCHIVE_NAME="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESS_LEVEL="$2"
            shift 2
            ;;
        -k|--keep)
            KEEP_ARCHIVE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Quiet mode function
log() {
    if [ "$QUIET" = false ]; then
        print_info "$1"
    fi
}

# Main script
main() {
    log "Starting ollama models archive and split process..."
    
    # Validate input directory
    if [ ! -d "$MODELS_DIR" ]; then
        print_error "Models directory not found: $MODELS_DIR"
        print_info "Make sure ollama is installed and has downloaded models"
        exit 1
    fi
    
    # Check if models directory is empty
    if [ -z "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]; then
        print_error "Models directory is empty: $MODELS_DIR"
        print_info "Download some models first using: ollama pull <model-name>"
        exit 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Change to output directory
    cd "$OUTPUT_DIR"
    
    # Remove existing files
    if ls ${ARCHIVE_NAME}* >/dev/null 2>&1; then
        log "Removing existing ${ARCHIVE_NAME}* files..."
        rm -f ${ARCHIVE_NAME}*
    fi
    
    # Show directory size
    MODELS_SIZE=$(du -sh "$MODELS_DIR" 2>/dev/null | cut -f1 || echo "unknown")
    log "Models directory size: $MODELS_SIZE"
    
    # Create compressed archive
    log "Creating compressed archive..."
    ARCHIVE_FILE="${ARCHIVE_NAME}.tar.gz"
    
    print_info "Archiving: $MODELS_DIR -> $ARCHIVE_FILE"
    tar -czf "$ARCHIVE_FILE" -C "$(dirname "$MODELS_DIR")" "$(basename "$MODELS_DIR")"
    
    # Check if archive was created successfully
    if [ ! -f "$ARCHIVE_FILE" ]; then
        print_error "Failed to create archive: $ARCHIVE_FILE"
        exit 1
    fi
    
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_FILE" | cut -f1)
    log "Archive created: $ARCHIVE_FILE ($ARCHIVE_SIZE)"
    
    # Split the archive
    log "Splitting archive into ${SPLIT_SIZE} parts..."
    split -b "$SPLIT_SIZE" -d -a 2 "$ARCHIVE_FILE" "${ARCHIVE_NAME}-part-"
    
    # Count and show split files
    SPLIT_FILES=(${ARCHIVE_NAME}-part-*)
    SPLIT_COUNT=${#SPLIT_FILES[@]}
    
    if [ $SPLIT_COUNT -eq 0 ]; then
        print_error "No split files were created"
        exit 1
    fi
    
    print_success "Created $SPLIT_COUNT split files:"
    
    for file in "${SPLIT_FILES[@]}"; do
        if [ -f "$file" ]; then
            FILE_SIZE=$(du -sh "$file" | cut -f1)
            if [ "$QUIET" = false ]; then
                echo "  - $file ($FILE_SIZE)"
            fi
        fi
    done
    
    # Remove original archive unless keeping it
    if [ "$KEEP_ARCHIVE" = false ]; then
        log "Removing original archive..."
        rm -f "$ARCHIVE_FILE"
    else
        log "Keeping original archive: $ARCHIVE_FILE"
    fi
    
    # Final summary
    print_success "Process completed successfully!"
    print_info "Files created in: $OUTPUT_DIR"
    print_info "Upload these files to GitHub: ${ARCHIVE_NAME}-part-*"
    
    # Show reassembly command
    echo
    print_info "To reassemble later, use:"
    echo "  cat ${ARCHIVE_NAME}-part-* > ${ARCHIVE_NAME}.tar.gz"
    echo "  tar -xzf ${ARCHIVE_NAME}.tar.gz"
}

# Run main function
main "$@"
