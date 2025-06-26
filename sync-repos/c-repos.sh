#!/bin/bash

# claude-repo-navigator.sh
# Lists all git repositories with clickable file:// links

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATHS_FILE="$SCRIPT_DIR/repo-paths.txt"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Main execution
main() {
    echo -e "${BLUE}Git Repositories${NC}"
    echo -e "${BLUE}================${NC}"
    
    # Check if config file exists
    if [[ ! -f "$REPO_PATHS_FILE" ]]; then
        echo -e "${YELLOW}Error: Configuration file not found: $REPO_PATHS_FILE${NC}"
        exit 1
    fi
    
    local repo_count=0
    
    # Read paths from config file and find repositories
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Expand tilde
        expanded_path=$(eval echo "$line")
        
        # Check if directory exists
        if [[ ! -d "$expanded_path" ]]; then
            echo -e "${YELLOW}Warning: Directory not found: $expanded_path${NC}"
            continue
        fi
        
        # Find all git repositories (excluding zOLD directories)
        while IFS= read -r -d '' repo_dir; do
            # Get the parent directory (the actual repo directory)
            repo_path=$(dirname "$repo_dir")
            
            # Skip if in zOLD directory
            [[ "$repo_path" == *"/zOLD"* ]] && continue
            
            # Get repo name from path
            repo_name=$(basename "$repo_path")
            
            # Output clickable file:// link with highlighted repo name at the end
            echo -e "file://${repo_path%/*}/${GREEN}${repo_name}${NC}"
            ((repo_count++))
            
        done < <(find "$expanded_path" -name ".git" -type d -print0 2>/dev/null)
        
    done < "$REPO_PATHS_FILE"
}

# Run main function
main "$@"