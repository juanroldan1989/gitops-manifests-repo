#!/bin/bash

# Get the current directory (where the script is located)
CURRENT_DIR="$(pwd)"

echo "Searching for .terragrunt-cache folders in $CURRENT_DIR..."

# Find and remove all .terragrunt-cache directories recursively
find "$CURRENT_DIR" -type d -name ".terragrunt-cache" -exec rm -rf {} +

echo "All .terragrunt-cache folders removed from $CURRENT_DIR."
