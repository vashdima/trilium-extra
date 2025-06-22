# === Config ===
REPO := vashdima/trilium-extra
TAG := 0.1
DIR := assets
OUTPUT := ollama.tar.gz
MODELS_OUTPUT := ollama-models.zip

# === Targets ===
.PHONY: all download-and-combine clean

all: download-and-combine

download-and-combine:
	@mkdir -p $(DIR)
	@echo "Fetching asset URLs from release $(TAG)..."
	@ASSET_URLS=$$(curl -s https://api.github.com/repos/$(REPO)/releases/tags/$(TAG) | jq -r '.assets[].browser_download_url'); \
	if [ -z "$$ASSET_URLS" ]; then \
		echo "No assets found in release $(TAG)"; \
		exit 1; \
	fi; \
	\
	if [ ! -f $(DIR)/$(OUTPUT) ]; then \
		echo "$(DIR)/$(OUTPUT) does not exist, downloading and combining ollama_part_ files..."; \
		OLLAMA_URLS=$$(echo "$$ASSET_URLS" | grep "ollama_part_"); \
		if [ -n "$$OLLAMA_URLS" ]; then \
			TOTAL=$$(echo "$$OLLAMA_URLS" | wc -l); COUNT=0; \
			for url in $$OLLAMA_URLS; do \
				COUNT=$$((COUNT + 1)); \
				filename=$$(basename $$url); \
				echo "[ $$COUNT / $$TOTAL ] Downloading $$filename ..."; \
				curl -L --fail --retry 3 --progress-bar --output $(DIR)/$$filename $$url; \
			done; \
			echo "Combining ollama parts into $(DIR)/$(OUTPUT)..."; \
			cat $(DIR)/ollama_part_* > $(DIR)/$(OUTPUT); \
			echo "Removing ollama part files..."; \
			rm -f $(DIR)/ollama_part_*; \
		fi; \
	else \
		echo "$(DIR)/$(OUTPUT) already exists, skipping ollama processing..."; \
	fi; \
	\
	if [ ! -f $(DIR)/$(MODELS_OUTPUT) ]; then \
		echo "$(DIR)/$(MODELS_OUTPUT) does not exist, downloading and combining ollama-models-part- files..."; \
		MODELS_URLS=$$(echo "$$ASSET_URLS" | grep "ollama-models-part-"); \
		if [ -n "$$MODELS_URLS" ]; then \
			TOTAL=$$(echo "$$MODELS_URLS" | wc -l); COUNT=0; \
			for url in $$MODELS_URLS; do \
				COUNT=$$((COUNT + 1)); \
				filename=$$(basename $$url); \
				echo "[ $$COUNT / $$TOTAL ] Downloading $$filename ..."; \
				curl -L --fail --retry 3 --progress-bar --output $(DIR)/$$filename $$url; \
			done; \
			echo "Combining ollama-models parts into $(DIR)/$(MODELS_OUTPUT)..."; \
			cat $(DIR)/ollama-models-part-* > $(DIR)/$(MODELS_OUTPUT); \
			echo "Removing ollama-models part files..."; \
			rm -f $(DIR)/ollama-models-part-*; \
		fi; \
	else \
		echo "$(DIR)/$(MODELS_OUTPUT) already exists, skipping ollama-models processing..."; \
	fi

clean:
	@echo "Cleaning up..."
	@rm -rf $(DIR)
