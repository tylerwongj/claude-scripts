# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Architecture

This repository contains development utility scripts organized into functional categories:

- **sync-repos/**: Git repository management tools for bulk operations across multiple repos
- **game-testing/**: Scripts for managing game development projects (start/stop/cleanup)
- **zOLD/**: Legacy scripts (excluded from automatic syncing)
- **Root level**: Core automation and sync utilities

## Essential Commands

### Script Management
```bash
# Sync all scripts as shell aliases to ~/dotfiles/bash/modules/claude.sh
./_sync-all-scripts-to-claude.sh

# After syncing, reload shell to use aliases
source ~/.bashrc
```

### Git Repository Operations
```bash
# Push all repositories configured in sync-repos/repo-paths.txt
./sync-repos/claude-push-all.sh

# Pull all repositories
./sync-repos/claude-pull-all.sh

# Full sync (pull then push) all repositories
./sync-repos/claude-sync-all.sh sync

# Use custom config file
./sync-repos/claude-sync-all.sh sync /path/to/custom-config.txt
```

### Game Development
```bash
# Start all game servers
./game-testing/claude-start-games.sh

# Stop all game servers
./game-testing/claude-stop-games.sh

# Clean up game projects
./game-testing/claude-cleanup-projects.sh
```

## Repository Management System

The sync-repos system automatically discovers git repositories in configured directories:
- Reads paths from `sync-repos/repo-paths.txt`
- Recursively finds all `.git` repositories in those paths
- Excludes `/zOLD` directories automatically
- Handles uncommitted changes, missing remotes, and branch tracking
- Provides colored output with detailed success/failure reporting

Configuration file format:
```
~/p2
~/dotfiles
~/p6
```

## Script Discovery & Aliasing

The `_sync-all-scripts-to-claude.sh` utility:
- Finds all scripts starting with "claude-" or ending with ".sh"
- Searches up to 2 directory levels deep (maxdepth 2)
- Excludes files starting with "_" and anything in zOLD directories
- Creates shell aliases in ~/dotfiles/bash/modules/claude.sh
- Removes .sh extensions from alias names for cleaner commands

## Integration Notes

Scripts are designed to integrate with dotfiles bash module system for global command availability. The sync utility automatically maintains aliases so new scripts become immediately available after running the sync command.