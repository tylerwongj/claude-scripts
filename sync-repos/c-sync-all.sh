#!/bin/bash

# Git Sync All - Push/Pull all repositories from configuration file
# Usage: ./git-sync-all.sh [push|pull|sync] [config-file]

set -e

# Default configuration file
CONFIG_FILE="${2:-$(dirname "$0")/repo-paths.txt}"
ACTION="${1:-sync}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to find all git repositories in a directory
find_git_repos() {
    local base_path="$1"
    local expanded_path="${base_path/#\~/$HOME}"
    
    if [[ ! -d "$expanded_path" ]]; then
        print_warning "Directory not found: $expanded_path"
        return
    fi
    
    # Find all .git directories, excluding zOLD
    find "$expanded_path" -name ".git" -type d | while read -r git_dir; do
        repo_path=$(dirname "$git_dir")
        
        # Skip if path contains zOLD
        if [[ "$repo_path" == *"/zOLD/"* ]] || [[ "$repo_path" == *"/zOLD" ]]; then
            continue
        fi
        
        # Check if repo has a remote
        if ! (cd "$repo_path" && git remote | grep -q .); then
            continue
        fi
        
        echo "$repo_path"
    done
}

# Function to get all repository paths from config
get_all_repos() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    local repos=()
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Find git repos in this path
        while IFS= read -r repo; do
            [[ -n "$repo" ]] && repos+=("$repo")
        done < <(find_git_repos "$line")
        
    done < "$CONFIG_FILE"
    
    # Remove duplicates and sort
    printf '%s\n' "${repos[@]}" | sort -u
}

# Function to check if repo has changes
has_changes() {
    local repo_path="$1"
    cd "$repo_path"
    
    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        return 0
    fi
    
    # Check for untracked files
    if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        return 0
    fi
    
    return 1
}

# Function to get branch info
get_branch_info() {
    local repo_path="$1"
    cd "$repo_path"
    
    local branch=$(git branch --show-current)
    local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
    
    echo "$branch|$remote_branch"
}

# Function to pull repository
pull_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    cd "$repo_path"
    
    # Check if it's a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "PULL: Not a git repository"
        return 1
    fi
    
    # Get branch info
    local branch_info=$(get_branch_info "$repo_path")
    local current_branch=$(echo "$branch_info" | cut -d'|' -f1)
    local remote_branch=$(echo "$branch_info" | cut -d'|' -f2)
    
    if [[ -z "$remote_branch" ]]; then
        print_warning "PULL: No remote tracking branch set"
        return 1
    fi
    
    # Check for uncommitted changes before pulling
    if has_changes "$repo_path"; then
        print_warning "PULL: Has uncommitted changes, skipping"
        return 1
    fi
    
    local pull_output=$(git pull --rebase 2>&1)
    local pull_exit_code=$?
    
    if [[ $pull_exit_code -eq 0 ]]; then
        if [[ "$pull_output" == *"Already up to date"* ]] || [[ "$pull_output" == *"up to date"* ]]; then
            print_status "PULL: Already up to date"
        else
            print_success "PULL: Successfully pulled changes"
        fi
        return 0
    else
        print_error "PULL: Failed - $pull_output"
        return 1
    fi
}

# Function to push repository
push_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    cd "$repo_path"
    
    # Check if it's a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "PUSH: Not a git repository"
        return 1
    fi
    
    # Check if there are any commits
    if ! git rev-parse HEAD > /dev/null 2>&1; then
        print_warning "PUSH: No commits found"
        return 1
    fi
    
    # Get branch info
    local branch_info=$(get_branch_info "$repo_path")
    local current_branch=$(echo "$branch_info" | cut -d'|' -f1)
    local remote_branch=$(echo "$branch_info" | cut -d'|' -f2)
    
    # Check for uncommitted changes
    if has_changes "$repo_path"; then
        print_warning "PUSH: Has uncommitted changes, skipping"
        return 1
    fi
    
    # Check if remote exists
    if [[ -z "$remote_branch" ]]; then
        # Try to push to origin with current branch name
        # Try to push to origin with current branch name (silent attempt)
        if git push -u origin "$current_branch"; then
            print_success "PUSH: Successfully pushed and set upstream"
            return 0
        else
            print_error "PUSH: Failed to push to origin"
            return 1
        fi
    fi
    
    # Check if we're ahead of remote
    local ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
    if [[ "$ahead" == "0" ]]; then
        print_status "PUSH: Already up to date with remote"
        return 0
    fi
    
    if git push; then
        print_success "PUSH: Successfully pushed"
        return 0
    else
        print_error "PUSH: Failed to push"
        return 1
    fi
}

# Function to sync repository (pull then push)
sync_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    # First pull
    if pull_repo "$repo_path"; then
        # Then push
        push_repo "$repo_path"
    else
        print_error "SYNC: Failed due to pull error"
        return 1
    fi
}

# Main execution
main() {
    print_status "Git Sync All - $ACTION mode"
    print_status "Configuration file: $CONFIG_FILE"
    
    # Get all repositories
    local repos=($(get_all_repos))
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_error "No git repositories found"
        exit 1
    fi
    
    print_status "Found ${#repos[@]} repositories"
    
    local success_count=0
    local fail_count=0
    
    # Process each repository
    for repo in "${repos[@]}"; do
        echo
        repo_name=$(basename "$repo")
        echo -e "📁 ${MAGENTA}$repo_name${NC}: file://$repo"
        case "$ACTION" in
            "pull")
                if pull_repo "$repo"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
                ;;
            "push")
                if push_repo "$repo"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
                ;;
            "sync")
                if sync_repo "$repo"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
                ;;
            *)
                print_error "Unknown action: $ACTION"
                print_status "Usage: $0 [push|pull|sync] [config-file]"
                exit 1
                ;;
        esac
    done
    
    # Summary
    echo
    print_status "Summary: $success_count successful, $fail_count failed"
    
    if [[ $fail_count -gt 0 ]]; then
        exit 1
    fi
}

# Run main function
main "$@"