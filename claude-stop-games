#!/bin/bash

# Script to stop all running games
echo "🛑 Stopping all games..."

# Kill all node processes running on ports 3000-3020
for port in {3000..3020}; do
    PID=$(lsof -ti:$port)
    if [ ! -z "$PID" ]; then
        echo "🔌 Stopping game on port $port (PID: $PID)"
        kill $PID 2>/dev/null
    fi
done

echo "✅ All games stopped!"