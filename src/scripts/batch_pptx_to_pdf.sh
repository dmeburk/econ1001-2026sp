#!/bin/bash

# Target directory
SEARCH_DIR="${1:-./lectures}"

# Create a temporary working file path
TMP_PDF="/tmp/transfer_output.pdf"

echo "🚀 Starting Sandbox-Proof Conversion..."

# Clean up any old temp files
rm -f "$TMP_PDF"

find "$SEARCH_DIR" -name "*.pptx" -type f -print0 | while IFS= read -r -d '' pptx_file; do
    # Get the absolute path for the PowerPoint
    # Using a portable way to get the absolute path
    abs_path=$(python3 -c "import os, sys; print(os.path.abspath(sys.argv[1]))" "$pptx_file")
    
    # Define where the PDF SHOULD end up
    final_pdf_path="${abs_path%.pptx}.pdf"
    
    echo "📄 Processing: $(basename "$pptx_file")"

    # AppleScript: Save to /tmp/ instead of the OneDrive folder
    osascript <<EOD
        tell application "Microsoft PowerPoint"
            activate
            open POSIX file "$abs_path"
            set activePres to active presentation
            
            -- Save to the neutral /tmp/ directory to bypass sandbox blocks
            save activePres in POSIX file "$TMP_PDF" as save as PDF
            
            close activePres saving no
        end tell
EOD

    # --- THE MOVE & VERIFY ---
    # Give it 1 second to make sure the write finished
    sleep 1

    if [ -f "$TMP_PDF" ]; then
        mv "$TMP_PDF" "$final_pdf_path"
        echo "   ✅ Success! Saved to: $final_pdf_path"
    else
        echo "   ❌ Error: PowerPoint failed to write the temp file."
        echo "      Make sure PowerPoint isn't showing a 'Grant Access' popup!"
    fi
    echo "------------------------------------------------"
done

echo "✅ All done."