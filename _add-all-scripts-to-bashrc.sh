#!/bin/bash

# Add All Scripts to Aliases - Automatically finds and adds all scripts as aliases
# Usage: ./_add-all-scripts-to-bashrc.sh

SCRIPT_DIR="/Users/tyler/p2/claude-scripts"
CLAUDE_MODULE="$HOME/dotfiles/bash/modules/claude.sh"

echo "🤖 Creating claude.sh module with all scripts..."
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

# Create the claude.sh module
echo "📝 Creating claude.sh module..."
cat > "$CLAUDE_MODULE" << 'EOF'
#!/bin/bash

# Claude AI Scripts Module
# Auto-generated aliases for Claude-related scripts and tools

EOF

# Function to add alias to claude module
add_alias() {
    local script_path="$1"
    local alias_name=$(basename "$script_path")
    
    echo "➡️  Adding: $alias_name"
    
    # Add to claude module
    echo "alias $alias_name='$script_path'" >> "$CLAUDE_MODULE"
    
    # Load alias in current session
    alias "$alias_name"="$script_path"
    echo "✅ Alias loaded in current session"
}

# Add each script as an alias
echo "➕ Adding all scripts as aliases..."
for script in "${scripts[@]}"; do
    add_alias "$script"
done
echo ""

echo "✅ claude.sh module created successfully"

echo "🎉 All scripts processed!"
echo ""
echo "💡 Available script commands:"
for script in "${scripts[@]}"; do
    alias_name=$(basename "$script")
    printf "   %-25s - %s\n" "$alias_name" "$script"
done

echo ""
echo "🚀 Run 'source ~/.bashrc' or open a new terminal to load all aliases"