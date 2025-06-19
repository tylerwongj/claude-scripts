#!/bin/bash

# Script to pull latest changes from master/main branch in all git repositories
# Usage: ./pull-all-repos.sh [directory]
# If no directory is provided, uses current directory

TARGET_DIR="${1:-$(pwd)}"

echo "Checking for git repositories in: $TARGET_DIR"
echo "=========================================="

# Counter for tracking repositories
repo_count=0
updated_count=0

# Find all directories that contain a .git folder
while IFS= read -r -d '' git_dir; do
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    
    # Skip zOLD directories
    if [[ "$repo_dir" == *"/zOLD"* ]]; then
        echo "Skipping zOLD directory: $repo_name"
        continue
    fi
    
    echo "Processing: $repo_name"
    cd "$repo_dir" || continue
    
    repo_count=$((repo_count + 1))
    
    # Check if it's actually a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "  ❌ Not a valid git repository"
        continue
    fi
    
    # Get current branch name
    current_branch=$(git branch --show-current 2>/dev/null)
    
    # Determine main branch (master or main)
    main_branch=""
    if git show-ref --verify --quiet refs/heads/master; then
        main_branch="master"
    elif git show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    else
        echo "  ⚠️  No master or main branch found"
        continue
    fi
    
    # Switch to main branch if not already on it
    if [ "$current_branch" != "$main_branch" ]; then
        echo "  🔄 Switching from $current_branch to $main_branch"
        git checkout "$main_branch" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "  ❌ Failed to switch to $main_branch"
            continue
        fi
    fi
    
    # Check if there are any uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "  ⚠️  Has uncommitted changes, skipping pull"
        continue
    fi
    
    # Fetch and check if there are updates
    echo "  🔍 Checking for updates..."
    git fetch origin "$main_branch" > /dev/null 2>&1
    
    # Compare local and remote
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "  ⚠️  No upstream branch configured"
        continue
    fi
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "  ✅ Already up to date"
    else
        echo "  📥 Pulling latest changes..."
        git pull origin "$main_branch"
        if [ $? -eq 0 ]; then
            echo "  ✅ Successfully updated"
            updated_count=$((updated_count + 1))
        else
            echo "  ❌ Failed to pull changes"
        fi
    fi
    
    echo ""
    
done < <(find "$TARGET_DIR" -maxdepth 2 -name ".git" -type d -print0)

echo "=========================================="
echo "Summary:"
echo "  📁 Repositories checked: $repo_count"
echo "  📥 Repositories updated: $updated_count"
echo "Done!"