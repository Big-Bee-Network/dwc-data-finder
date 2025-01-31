#!/bin/bash

# =============================================================================
# Script Name: filter_catalog_numbers_csv.sh
# Description: Filters records from occurrences.csv based on a list of catalogNumbers.
# Usage: ./filter_catalog_numbers_csv.sh [EXTRACTED_DIR] [CATALOG_NUMBERS_FILE] [OUTPUT_FILE]
#        - EXTRACTED_DIR: Directory where occurrences.csv is located (default: ./extracted)
#        - CATALOG_NUMBERS_FILE: File containing catalogNumbers (default: ./catalogNumbers.txt)
#        - OUTPUT_FILE: File to save the filtered records (default: filtered_occurrences.csv)
# =============================================================================

# -------------------------------
# Function: print_usage
# Description: Displays usage instructions
# -------------------------------
print_usage() {
    echo "Usage: $0 [EXTRACTED_DIR] [CATALOG_NUMBERS_FILE] [OUTPUT_FILE]"
    echo ""
    echo "Arguments:"
    echo "  EXTRACTED_DIR          Directory containing occurrences.csv. Default: ./extracted"
    echo "  CATALOG_NUMBERS_FILE   File with catalogNumbers, one per line. Default: ./catalogNumbers.txt"
    echo "  OUTPUT_FILE            File to save filtered records. Default: filtered_occurrences.csv"
    echo ""
    echo "Example:"
    echo "  $0 ./extracted ./catalogNumbers.txt ./filtered_records.csv"
}

# -------------------------------
# Function: check_dependencies
# Description: Checks if required commands are available
# -------------------------------
check_dependencies() {
    local dependencies=(awk grep)
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
DEFAULT_EXTRACTED_DIR="./extracted"
DEFAULT_CATALOG_FILE="./catalogNumbers.txt"
DEFAULT_OUTPUT_FILE="./filtered_occurrences.csv"

# Parse arguments
EXTRACTED_DIR="${1:-$DEFAULT_EXTRACTED_DIR}"
CATALOG_FILE="${2:-$DEFAULT_CATALOG_FILE}"
OUTPUT_FILE="${3:-$DEFAULT_OUTPUT_FILE}"

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
    exit 0
fi

# Check for required dependencies
check_dependencies

# Define the occurrences file path
OCCURRENCES_FILE="$EXTRACTED_DIR/occurrences.csv"

# Check if occurrences.csv exists
if [[ ! -f "$OCCURRENCES_FILE" ]]; then
    echo "Error: $OCCURRENCES_FILE does not exist."
    exit 1
fi

# Check if catalogNumbers file exists
if [[ ! -f "$CATALOG_FILE" ]]; then
    echo "Error: $CATALOG_FILE does not exist."
    exit 1
fi

echo "Filtering records from $OCCURRENCES_FILE based on $CATALOG_FILE..."

# Extract the header
head -n 1 "$OCCURRENCES_FILE" > "$OUTPUT_FILE"

# Get the column number for catalogNumber (case-sensitive)
CATALOG_COLUMN=$(head -n 1 "$OCCURRENCES_FILE" | tr ',' '\n' | nl | grep -w "catalogNumber" | awk '{print $1}')

if [[ -z "$CATALOG_COLUMN" ]]; then
    echo "Error: 'catalogNumber' column not found in $OCCURRENCES_FILE."
    exit 1
fi

echo "catalogNumber found at column: $CATALOG_COLUMN"

# Use awk to filter records
awk -v col="$CATALOG_COLUMN" -F',' '
    NR==FNR {gsub(/"/, "", $1); catalog[$1]; next}
    FNR==1 {next} # Skip header
    {
        # Remove potential quotes and whitespace
        gsub(/"/, "", $col)
        if ($col in catalog) {
            print
        }
    }
' "$CATALOG_FILE" "$OCCURRENCES_FILE" >> "$OUTPUT_FILE"

echo "Filtered records saved to $OUTPUT_FILE."
exit 0
