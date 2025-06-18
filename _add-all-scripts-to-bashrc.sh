#!/bin/bash

# Add All Scripts to Bashrc - Automatically finds and adds all claude-* scripts as aliases
# Usage: ./_add-all-scripts-to-bashrc.sh

SCRIPT_DIR="/Users/tyler/p2/claude-scripts"

echo "🤖 Adding all claude-* scripts to .bashrc as aliases..."
echo "📍 Script directory: $SCRIPT_DIR"
echo ""

# Find all files starting with "claude-" 
scripts=($(find "$SCRIPT_DIR" -name "claude-*" -type f | sort))

if [ ${#scripts[@]} -eq 0 ]; then
    echo "❌ No claude-* scripts found in $SCRIPT_DIR"
    exit 1
fi

echo "🔍 Found ${#scripts[@]} claude-* scripts:"
for script in "${scripts[@]}"; do
    basename "$script"
done
echo ""

# Remove existing AI block completely and regenerate fresh
echo "🧹 Removing old AI aliases block..."
if grep -q "# AI - /claude-scripts auto-generated aliases" ~/.bashrc; then
    # Find start and end of AI block
    start_line=$(grep -n "# AI - /claude-scripts auto-generated aliases" ~/.bashrc | cut -d: -f1)
    
    # Find the end (next comment line or end of file)
    end_line=$(tail -n +$((start_line + 1)) ~/.bashrc | grep -n "^#" | head -1 | cut -d: -f1)
    if [ -n "$end_line" ]; then
        end_line=$((start_line + end_line))
    else
        end_line=$(wc -l < ~/.bashrc)
        end_line=$((end_line + 1))
    fi
    
    # Remove the entire AI block
    sed -i.bak "${start_line},$((end_line - 1))d" ~/.bashrc
    echo "✅ Removed old AI aliases block"
fi
echo ""

# Function to add alias to temp file
add_alias() {
    local script_path="$1"
    local alias_name=$(basename "$script_path")
    
    echo "➡️  Adding: $alias_name"
    
    # Add to temp file
    echo "alias $alias_name='$script_path'" >> ~/.bashrc.tmp
    
    # Load alias in current session
    alias "$alias_name"="$script_path"
    echo "✅ Alias loaded in current session"
}

# Create temporary file for collecting aliases
rm -f ~/.bashrc.tmp

# Add each script as an alias
echo "➕ Adding all scripts as aliases..."
for script in "${scripts[@]}"; do
    add_alias "$script"
done
echo ""

# Add the fresh AI block to .bashrc
if [ -f ~/.bashrc.tmp ]; then
    echo "📍 Creating fresh AI aliases block..."
    echo "# AI - /claude-scripts auto-generated aliases" >> ~/.bashrc
    cat ~/.bashrc.tmp >> ~/.bashrc
    rm -f ~/.bashrc.tmp
    echo "✅ Fresh AI block added with all current scripts"
fi

echo "🎉 All claude-* scripts processed!"
echo ""
echo "💡 Available Claude commands:"
for script in "${scripts[@]}"; do
    alias_name=$(basename "$script")
    printf "   %-25s - %s\n" "$alias_name" "$script"
done

echo ""
echo "🚀 Run 'source ~/.bashrc' to load all aliases in new terminals"