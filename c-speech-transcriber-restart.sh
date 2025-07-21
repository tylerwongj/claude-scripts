#!/bin/bash

# Script to restart speech transcriber service
# Runs stop.sh first, then adds to login items

SPEECH_DIR="$HOME/p2/speech-transcriber"

echo "Stopping speech transcriber..."
cd "$SPEECH_DIR" && ./stop-transcriber.sh

echo "Adding speech transcriber to login items..."
cd "$SPEECH_DIR" && ./add-this-script-to-login-items.sh

echo "Speech transcriber restart complete"