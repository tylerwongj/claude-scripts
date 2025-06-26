#!/bin/bash

# Sync All Scripts to Claude Module - Automatically finds and syncs all scripts as aliases
# Usage: ./_sync-all-scripts-to-claude.sh

SCRIPT_DIR="/Users/tyler/p2/claude-scripts"
CLAUDE_MODULE="$HOME/dotfiles/bash/modules/claude.sh"

echo "🤖 Syncing claude.sh module with all scripts..."
echo "📍 Script directory: $SCRIPT_DIR"
echo "📍 Claude module: $CLAUDE_MODULE"
echo ""

# Find all executable files starting with "claude-" or "c-" or ending with ".sh" (max 2 levels deep, excluding zOLD)
scripts=($(find "$SCRIPT_DIR" -maxdepth 2 -type f \( -name "claude-*" -o -name "c-*" -o -name "*.sh" \) ! -name "_*" ! -path "*/zOLD/*" | grep -v "\.tmp$" | sort))

if [ ${#scripts[@]} -eq 0 ]; then
    echo "❌ No scripts found in $SCRIPT_DIR"
    exit 1
fi

echo "🔍 Found ${#scripts[@]} scripts:"
for script in "${scripts[@]}"; do
    basename "$script"
done
echo ""

# Backup existing claude.sh and preserve non-auto-generated content
echo "📝 Updating claude.sh module (preserving existing aliases)..."

# Create temporary file to store content before auto-generated section
temp_file=$(mktemp)

# Extract everything before the auto-generated section and after it
if [ -f "$CLAUDE_MODULE" ]; then
    # Get content before START marker
    sed '/^# \[CC\] START - Claude Code AUTO-GENERATED Aliases/,$d' "$CLAUDE_MODULE" > "$temp_file"
    
    # Get content after END marker
    temp_after=$(mktemp)
    sed -n '/^# \[CC\] END - Claude Code AUTO-GENERATED Aliases/,$p' "$CLAUDE_MODULE" | tail -n +2 > "$temp_after"
else
    echo "#!/bin/bash" > "$temp_file"
    echo "" >> "$temp_file"
    temp_after=$(mktemp)
fi

# Start writing the new claude.sh file
cp "$temp_file" "$CLAUDE_MODULE"
echo "# [CC] START - Claude Code AUTO-GENERATED Aliases" >> "$CLAUDE_MODULE"

# Clean up temp file
rm "$temp_file"

# Function to add alias to claude module
add_alias() {
    local script_path="$1"
    local filename=$(basename "$script_path")
    # Remove .sh extension if present
    local alias_name="${filename%.sh}"
    
    echo "➡️  Adding: $alias_name"
    
    # Add to claude module
    echo "alias $alias_name='$script_path'" >> "$CLAUDE_MODULE"
    
    # Load alias in current session
    alias "$alias_name"="$script_path"
    echo "✅ Alias loaded in current session"
}

# Sync each script as an alias
echo "➕ Syncing all scripts as aliases..."
for script in "${scripts[@]}"; do
    add_alias "$script"
done

# Add END marker and restore content after it
echo "# [CC] END - Claude Code AUTO-GENERATED Aliases" >> "$CLAUDE_MODULE"
if [ -f "$temp_after" ] && [ -s "$temp_after" ]; then
    cat "$temp_after" >> "$CLAUDE_MODULE"
fi

# Clean up temp files
rm -f "$temp_after"
echo ""

echo "✅ claude.sh module synced successfully"

echo "🎉 All scripts processed!"
echo ""
echo "💡 Available script commands:"
for script in "${scripts[@]}"; do
    filename=$(basename "$script")
    alias_name="${filename%.sh}"
    printf "   %-25s - %s\n" "$alias_name" "$script"
done

echo ""
echo "🚀 Run 'source ~/.bashrc' or open a new terminal to load all aliases"