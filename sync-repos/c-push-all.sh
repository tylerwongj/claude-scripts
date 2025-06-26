#!/bin/bash
# Claude Push All - Push all repositories
exec "$(dirname "$0")/git-sync-all.sh" push "$@"