#!/bin/bash

# Script to start multiple games on different ports
# Usage: ./start-all-games.sh [number_of_games] [starting_folder]
# Examples:
#   ./start-all-games.sh              (start 10 games from beginning)
#   ./start-all-games.sh 5            (start 5 games from beginning)
#   ./start-all-games.sh 10 connect-4 (start 10 games starting from connect-4)
#   ./start-all-games.sh 5 pong       (start 5 games starting from pong)

MAX_GAMES=${1:-10}  # Default to 10 games if no argument provided
START_FROM=${2:-""}  # Optional starting folder
PORT_START=3000
CURRENT_PORT=$PORT_START
STARTED_COUNT=0

if [ -z "$START_FROM" ]; then
    echo "🎮 Starting up to $MAX_GAMES games alphabetically..."
else
    echo "🎮 Starting up to $MAX_GAMES games starting from '$START_FROM'..."
fi
echo "📋 Games will be available at:"

# Array to store the games we're starting
declare -a STARTED_GAMES=()

# Function to start a game
start_game() {
    local game_dir=$1
    local port=$2
    local game_name=$(basename "$game_dir")
    
    if [ -f "$game_dir/package.json" ] && [ -f "$game_dir/server.js" ]; then
        echo "🚀 Starting $game_name on port $port"
        echo "   http://localhost:$port"
        
        # Check if node_modules exists, install dependencies if not
        if [ ! -d "$game_dir/node_modules" ]; then
            echo "📦 Installing dependencies for $game_name..."
        fi
        
        # Start the game in a new terminal (macOS) - install deps first if needed
        osascript -e "tell application \"Terminal\" to do script \"cd '$game_dir' && npm install && PORT=$port npm start\""
        
        STARTED_GAMES+=("$game_name:$port")
        return 0
    else
        echo "⚠️  Skipping $game_name (no package.json or server.js found)"
        return 1
    fi
}

# Find and start games
FOUND_START=false
if [ -z "$START_FROM" ]; then
    FOUND_START=true  # Start from beginning if no starting folder specified
fi

for game_dir in */; do
    if [ $STARTED_COUNT -ge $MAX_GAMES ]; then
        break
    fi
    
    # Skip zOLD directory
    if [[ "$game_dir" == "zOLD/" ]]; then
        continue
    fi
    
    # Check if we've reached the starting folder
    if [ "$FOUND_START" = false ]; then
        game_name=$(basename "$game_dir")
        if [[ "$game_name" == "$START_FROM" ]]; then
            FOUND_START=true
        else
            continue  # Skip this game, haven't reached starting point yet
        fi
    fi
    
    if start_game "$PWD/$game_dir" $CURRENT_PORT; then
        ((CURRENT_PORT++))
        ((STARTED_COUNT++))
    fi
done

echo ""
echo "✅ Started $STARTED_COUNT games!"
echo ""
echo "🌐 Opening browser tabs..."

# Wait for servers to start up and check if they're ready
echo "⏳ Waiting for servers to start (this may take a while for first run due to npm install)..."
sleep 10

# Check if servers are ready before opening tabs
echo "🔍 Checking server status..."
for game_info in "${STARTED_GAMES[@]}"; do
    IFS=':' read -r name port <<< "$game_info"
    
    # Wait for this specific port to be ready (max 10 seconds)
    for i in {1..10}; do
        if curl -s "http://localhost:$port" > /dev/null 2>&1; then
            echo "✅ $name server ready on port $port"
            break
        else
            echo "⏳ Waiting for $name server on port $port... ($i/10)"
            sleep 1
        fi
    done
done

echo ""
echo "🌐 Opening browser tabs..."

# Open browser tabs for each game
for game_info in "${STARTED_GAMES[@]}"; do
    IFS=':' read -r name port <<< "$game_info"
    echo "   Opening $name: http://localhost:$port"
    open "http://localhost:$port"
done

echo ""
echo "🌐 Quick Access URLs:"
for game_info in "${STARTED_GAMES[@]}"; do
    IFS=':' read -r name port <<< "$game_info"
    echo "   $name: http://localhost:$port"
done

echo ""
echo "💡 Tips:"
echo "   • Use Cmd+Tab to switch between Terminal windows"
echo "   • Use Ctrl+Tab in Chrome to cycle between localhost tabs"
echo "   • Press Ctrl+C in any Terminal to stop that game"
echo "   • Run './stop-all-games.sh' to stop all games at once"