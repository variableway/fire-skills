#!/bin/bash
# Markdown Converter - Batch convert files to specified output directory
# Usage: ./convert.sh <output_dir> <file1> [file2] [file3] ...

set -euo pipefail

OUTPUT_DIR="${1:-.}"
shift || true

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <output_dir> <file1> [file2] ..."
    echo "Example: $0 ~/workspace/innate-revisit/km/notes/ document.pdf report.docx"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "[SKIP] File not found: $file"
        continue
    fi
    
    filename=$(basename "$file")
    ext="${filename##*.}"
    basename="${filename%.*}"
    
    case "${ext,,}" in
        docx|pptx|xlsx|xls)
            echo "[DOCX] Converting: $filename"
            uvx --with "markitdown[docx]" markitdown "$file" -o "$OUTPUT_DIR/${basename}.md"
            ;;
        pdf)
            echo "[PDF] Converting: $filename"
            uvx markitdown "$file" -o "$OUTPUT_DIR/${basename}.md"
            ;;
        html|htm)
            echo "[HTML] Converting: $filename"
            uvx markitdown "$file" -o "$OUTPUT_DIR/${basename}.md"
            ;;
        json|xml|csv)
            echo "[DATA] Converting: $filename"
            uvx markitdown "$file" -o "$OUTPUT_DIR/${basename}.md"
            ;;
        *)
            echo "[AUTO] Converting: $filename"
            uvx markitdown "$file" -o "$OUTPUT_DIR/${basename}.md"
            ;;
    esac
    
    echo "  → $OUTPUT_DIR/${basename}.md"
done

echo ""
echo "Done! Converted $# files to $OUTPUT_DIR"