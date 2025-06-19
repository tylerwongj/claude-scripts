#!/bin/bash

# Script to push changes from master/main branch in all git repositories
# Usage: ./push-all-repos.sh [directory] [--force]
# If no directory is provided, uses current directory
# Use --force flag to push even when behind remote (not recommended)

TARGET_DIR=""
FORCE_PUSH=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_PUSH=true
            shift
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Set default directory if not provided
TARGET_DIR="${TARGET_DIR:-$(pwd)}"

echo "Pushing changes in git repositories in: $TARGET_DIR"
if [ "$FORCE_PUSH" = true ]; then
    echo "⚠️  FORCE PUSH MODE ENABLED"
fi
echo "=========================================="

# Counter for tracking repositories
repo_count=0
pushed_count=0
skipped_count=0

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
        skipped_count=$((skipped_count + 1))
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
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # Switch to main branch if not already on it
    if [ "$current_branch" != "$main_branch" ]; then
        echo "  🔄 Switching from $current_branch to $main_branch"
        git checkout "$main_branch" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "  ❌ Failed to switch to $main_branch"
            skipped_count=$((skipped_count + 1))
            continue
        fi
    fi
    
    # Check if there are any uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "  ⚠️  Has uncommitted changes, skipping push"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # Check if upstream branch exists
    if ! git rev-parse @{u} > /dev/null 2>&1; then
        echo "  ⚠️  No upstream branch configured, skipping"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # Fetch latest to compare
    echo "  🔍 Checking remote status..."
    git fetch origin "$main_branch" > /dev/null 2>&1
    
    # Compare local and remote
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "  ✅ Already in sync with remote"
        continue
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "  ⚠️  Local branch is behind remote, run pull first"
        skipped_count=$((skipped_count + 1))
        continue
    elif [ "$REMOTE" = "$BASE" ]; then
        echo "  📤 Pushing local changes..."
        git push origin "$main_branch"
        if [ $? -eq 0 ]; then
            echo "  ✅ Successfully pushed"
            pushed_count=$((pushed_count + 1))
        else
            echo "  ❌ Failed to push"
            skipped_count=$((skipped_count + 1))
        fi
    else
        if [ "$FORCE_PUSH" = true ]; then
            echo "  ⚡ Force pushing (branches have diverged)..."
            git push --force-with-lease origin "$main_branch"
            if [ $? -eq 0 ]; then
                echo "  ✅ Successfully force pushed"
                pushed_count=$((pushed_count + 1))
            else
                echo "  ❌ Failed to force push"
                skipped_count=$((skipped_count + 1))
            fi
        else
            echo "  ⚠️  Branches have diverged, use --force flag or resolve manually"
            skipped_count=$((skipped_count + 1))
        fi
    fi
    
    echo ""
    
done < <(find "$TARGET_DIR" -maxdepth 2 -name ".git" -type d -print0)

echo "=========================================="
echo "Summary:"
echo "  📁 Repositories checked: $repo_count"
echo "  📤 Repositories pushed: $pushed_count"
echo "  ⏭️  Repositories skipped: $skipped_count"
echo "Done!"