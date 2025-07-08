#!/bin/bash

PROMPT="cd ~/tyler-arcade && claude 'create more games in /games-not-yet-tested folder. The games should not be repeats, so make sure to list the folder and avoid duplicate games. You can do games that are like card games, board games, any types of games. Create five of them and make sure to use the games in the /games folder as reference of how to integrate the packages from the packages folder.'"

# Script to open 1 iTerm window with specified number of tabs running Claude
# Usage: ./claude-auto-terminal [number_of_tabs] [prompt]
# Default: 5 tabs, uses PROMPT variable if no prompt provided

NUM_TABS=${1:-5}
if [ -n "$2" ]; then
    PROMPT="$2"
fi
echo "Opening iTerm with $NUM_TABS tabs in $WORK_DIR..."

# Generate AppleScript dynamically based on number of tabs
osascript << EOF
tell application "iTerm"
    create window with default profile
    tell current session of current window
        write text "$PROMPT"
    end tell

    -- Wait for claude to start then send shift+tab
    delay 2
    tell application "System Events"
        keystroke tab using shift down
    end tell
    delay 0.5

    -- Create additional tabs
    repeat $((NUM_TABS - 1)) times
        tell application "System Events"
            keystroke "t" using command down
        end tell
        delay 1
        tell current session of current window
            write text "$PROMPT"
        end tell

        -- Wait for claude to start then send shift+tab
        delay 2
        tell application "System Events"
            keystroke tab using shift down
        end tell
        delay 0.5
    end repeat
end tell
EOF

echo "iTerm with $NUM_TABS tabs opened with Claude command and shift+tab applied after each"