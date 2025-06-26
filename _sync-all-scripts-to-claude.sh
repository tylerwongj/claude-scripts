#!/bin/bash

# Sync All Scripts to Claude Module - Automatically finds and syncs all scripts as aliases
# Usage: ./_sync-all-scripts-to-claude.sh

SCRIPT_DIR="/Users/tyler/p2/claude-scripts"
CLAUDE_MODULE="$HOME/dotfiles/bash/modules/claude.sh"

echo "🤖 Syncing claude.sh module with all scripts..."
echo "📍 Script directory: $SCRIPT_DIR"
echo "📍 Claude module: $CLAUDE_MODULE"
echo ""

# Find all executable files starting with "claude-" or ending with ".sh"
scripts=($(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -name "claude-*" -o -name "*.sh" \) ! -name "_*" | grep -v "\.tmp$" | sort))

if [ ${#scripts[@]} -eq 0 ]; then
    echo "❌ No scripts found in $SCRIPT_DIR"
    exit 1
fi

echo "🔍 Found ${#scripts[@]} scripts:"
for script in "${scripts[@]}"; do
    basename "$script"
done
echo ""

# Sync the claude.sh module
echo "📝 Syncing claude.sh module..."
cat > "$CLAUDE_MODULE" << 'EOF'
#!/bin/bash

# Claude AI Scripts Module
# Auto-generated aliases for Claude-related scripts and tools

EOF

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