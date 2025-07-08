#!/bin/bash

# Create zOLD directory if it doesn't exist
mkdir -p zOLD

# Loop through all directories in current directory
for dir in */; do
    # Skip if it's already the zOLD directory
    if [ "$dir" = "zOLD/" ]; then
        continue
    fi
    
    # Remove trailing slash for cleaner directory name
    dirname="${dir%/}"
    
    # Check if .good file exists in the directory
    if [ ! -f "$dirname/.good" ]; then
        echo "Moving $dirname to zOLD (no .good file found)"
        mv "$dirname" zOLD/
    else
        echo "Keeping $dirname (.good file found)"
    fi
done

echo "Cleanup complete!"