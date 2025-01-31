#!/bin/bash

# =============================================================================
# Script Name: download_images.sh
# Description: Downloads images associated with each catalogNumber by matching
#              catalogNumber from catalogNumbers.txt to occurrences.csv to get id,
#              then matching id to coreid in multimedia.csv to get accessURI,
#              and downloading the image using curl with a numerical prefix.
# Usage: ./download_images.sh [CATALOG_NUMBERS_FILE] [EXTRACTED_DIR] [OUTPUT_DIR]
#        - CATALOG_NUMBERS_FILE: File containing catalogNumbers (default: catalogNumbers.txt)
#        - EXTRACTED_DIR: Directory containing occurrences.csv and multimedia.csv (default: ./extracted)
#        - OUTPUT_DIR: Directory to save downloaded images (default: ./images)
# =============================================================================

# -------------------------------
# Function: print_usage
# Description: Displays usage instructions
# -------------------------------
print_usage() {
    echo "Usage: $0 [CATALOG_NUMBERS_FILE] [EXTRACTED_DIR] [OUTPUT_DIR]"
    echo ""
    echo "Arguments:"
    echo "  CATALOG_NUMBERS_FILE   File containing catalogNumbers, one per line. Default: catalogNumbers.txt"
    echo "  EXTRACTED_DIR          Directory containing occurrences.csv and multimedia.csv. Default: ./extracted"
    echo "  OUTPUT_DIR             Directory to save downloaded images. Default: ./images"
    echo ""
    echo "Example:"
    echo "  $0 catalogNumbers.txt ./extracted ./images"
}

# -------------------------------
# Function: check_dependencies
# Description: Checks if required commands are available
# -------------------------------
check_dependencies() {
    local dependencies=(csvjoin csvcut curl)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: '$cmd' is not installed. Please install it and retry."
            exit 1
        fi
    done
}

# -------------------------------
# Main Script Execution
# -------------------------------

# Default values
DEFAULT_CATALOG_FILE="./catalogNumbers.txt"
DEFAULT_EXTRACTED_DIR="./extracted"
DEFAULT_OUTPUT_DIR="./images"

# Parse arguments
CATALOG_FILE="${1:-$DEFAULT_CATALOG_FILE}"
EXTRACTED_DIR="${2:-$DEFAULT_EXTRACTED_DIR}"
OUTPUT_DIR="${3:-$DEFAULT_OUTPUT_DIR}"

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
    exit 0
fi

# Check for required dependencies
check_dependencies

# Check if input files exist
if [[ ! -f "$CATALOG_FILE" ]]; then
    echo "Error: Catalog numbers file '$CATALOG_FILE' does not exist."
    exit 1
fi

if [[ ! -f "$EXTRACTED_DIR/occurrences.csv" ]]; then
    echo "Error: Occurrences file '$EXTRACTED_DIR/occurrences.csv' does not exist."
    exit 1
fi

if [[ ! -f "$EXTRACTED_DIR/multimedia.csv" ]]; then
    echo "Error: Multimedia file '$EXTRACTED_DIR/multimedia.csv' does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Processing catalog numbers and preparing download list..."

# Join occurrences.csv and multimedia.csv on id and coreid
# Assuming 'id' in occurrences.csv matches 'coreid' in multimedia.csv
csvjoin -c id,coreid "$EXTRACTED_DIR/occurrences.csv" "$EXTRACTED_DIR/multimedia.csv" > joined_data.csv

# Filter joined_data.csv to include only catalogNumbers from catalogNumbers.txt
csvgrep -c catalogNumber -f "$CATALOG_FILE" joined_data.csv > filtered_joined_data.csv

# Clean up temporary joined_data.csv
rm joined_data.csv

# Extract only catalogNumber and accessURI columns
csvcut -c catalogNumber,accessURI filtered_joined_data.csv > catalog_access.csv

# Remove the header for processing
tail -n +2 catalog_access.csv > catalog_access_no_header.csv

# Clean up temporary files
rm filtered_joined_data.csv catalog_access.csv

echo "Starting image downloads..."

# Initialize counters
total_images=$(wc -l < catalog_access_no_header.csv)
downloaded=0
failed=0
counter=1

# Read each line and download the image
while IFS=',' read -r catalogNumber accessURI
do
    # Remove quotes if present
    cleanCatalogNumber=$(echo "$catalogNumber" | tr -d '"')
    cleanAccessURI=$(echo "$accessURI" | tr -d '"')

    # Validate accessURI
    if [[ "$cleanAccessURI" != http* ]]; then
        echo "[$counter/$total_images] Invalid URL for $cleanCatalogNumber: $cleanAccessURI"
        failed=$((failed + 1))
        counter=$((counter + 1))
        continue
    fi

    # Determine the image extension from the URL
    extension="${cleanAccessURI##*.}"
    # Handle query parameters in URL by stripping them
    extension="${extension%%\?*}"
    # Convert to lowercase
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Default to jpg if extension is not recognized
    if [[ ! "$extension" =~ ^(jpg|jpeg|png|gif|bmp|tiff)$ ]]; then
        extension="jpg"
    fi

    # Create image filename with numerical increment at the beginning
    imageFilename="${counter}_${cleanCatalogNumber}.${extension}"
    imagePath="$OUTPUT_DIR/$imageFilename"

    echo "[$counter/$total_images] Downloading image for $cleanCatalogNumber from $cleanAccessURI..."

    # Download the image using curl with retries
    curl -L --retry 3 "$cleanAccessURI" -o "$imagePath" -s

    # Check if download was successful
    if [[ $? -eq 0 && -s "$imagePath" ]]; then
        echo "[$counter/$total_images] Successfully downloaded to $imagePath"
        downloaded=$((downloaded + 1))
    else
        echo "[$counter/$total_images] Failed to download image from $cleanAccessURI"
        rm -f "$imagePath"  # Remove incomplete or empty file
        failed=$((failed + 1))
    fi

    counter=$((counter + 1))

done < catalog_access_no_header.csv

# Clean up temporary file
rm catalog_access_no_header.csv

echo "Image download completed."
echo "Total Images: $total_images"
echo "Downloaded Successfully: $downloaded"
echo "Failed Downloads: $failed"

exit 0
