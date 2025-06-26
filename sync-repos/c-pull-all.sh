#!/bin/bash
# Claude Pull All - Pull all repositories
exec "$(dirname "$0")/git-sync-all.sh" pull "$@"