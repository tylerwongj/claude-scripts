#!/bin/bash

# Claude Code Pro Limit Tracker
# Tracks Claude Code usage: 10-40 prompts per 5-hour session

# Find current time for 5-hour window calculation
current_epoch=$(date +%s)
window_start_epoch=$((current_epoch - (5 * 3600)))

# Find all session files and filter by modification time
all_session_files=$(find ~/.claude/projects -name "*.jsonl" -type f 2>/dev/null)
session_files=""

for file in $all_session_files; do
    file_mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
    if [ "$file_mtime" -gt "$window_start_epoch" ]; then
        session_files="$session_files $file"
    fi
done

if [ -z "$session_files" ]; then
    echo "❌ No Claude session files found in last 5 hours"
    exit 1
fi

# Find the earliest session start time within the window
earliest_start_epoch=$current_epoch
latest_end_epoch=0
total_prompt_count=0
total_chars=0

for session_file in $session_files; do
    # Get first message timestamp from this file
    first_message=$(grep '"type":"user"' "$session_file" | head -1)
    if [ -n "$first_message" ]; then
        session_start=$(echo "$first_message" | jq -r '.timestamp')
        session_start_clean=$(echo "$session_start" | sed 's/\.[0-9]*Z$/Z/')
        session_start_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$session_start_clean" +%s 2>/dev/null || echo "0")
        
        if [ "$session_start_epoch" != "0" ] && [ "$session_start_epoch" -lt "$earliest_start_epoch" ]; then
            earliest_start_epoch=$session_start_epoch
        fi
        
        # Count only actual user prompts (not tool results, bash outputs, or meta messages)
        file_prompt_count=$(grep '"type":"user"' "$session_file" | grep -v '"isMeta":true' | grep -v '<bash-' | grep -v 'tool_use_id' | wc -l)
        file_chars=$(grep '"type":"user"' "$session_file" | grep -v '"isMeta":true' | grep -v '<bash-' | grep -v 'tool_use_id' | jq -r '.message.content // empty' | wc -c)
        
        total_prompt_count=$((total_prompt_count + file_prompt_count))
        total_chars=$((total_chars + file_chars))
    fi
done

# Calculate session end time (5 hours from earliest start)
session_end_epoch=$((earliest_start_epoch + (5 * 3600)))
estimated_tokens=$((total_chars / 4))

# First 4 lines - most important info
echo "📊 Prompts used: $total_prompt_count | Est. tokens: ~$estimated_tokens"
echo "⏰ Session: $(TZ=America/Los_Angeles date -r $earliest_start_epoch '+%b %d %I:%M %p') → $(TZ=America/Los_Angeles date -r $session_end_epoch '+%b %d ⚡%I:%M %p⚡ %Z')"
echo "🎯 Assuming 40-prompt limit (more realistic than 10)"

# Check if session is still active
if [ $current_epoch -lt $session_end_epoch ]; then
    remaining_time=$((session_end_epoch - current_epoch))
    hours=$((remaining_time / 3600))
    minutes=$(((remaining_time % 3600) / 60))
    
    echo "🟢 Session active - ${hours}h ${minutes}m remaining"
    
    # Calculate based on 40-prompt assumption
    if [ $total_prompt_count -le 20 ]; then
        echo "✅ Low usage: $total_prompt_count/40 prompts (💚 $(( 40 - total_prompt_count )) remaining)"
    elif [ $total_prompt_count -le 30 ]; then
        echo "⚠️  Medium usage: $total_prompt_count/40 prompts (🟡 $(( 40 - total_prompt_count )) remaining)"
    elif [ $total_prompt_count -le 40 ]; then
        echo "🔶 High usage: $total_prompt_count/40 prompts (🟠 $(( 40 - total_prompt_count )) remaining)"
    else
        echo "🚫 Usage exceeded: $total_prompt_count/40 prompts (🔴 over limit)"
    fi
    
else
    echo "🔄 Session expired - new 5-hour session starts with next message"
fi

echo ""
echo "ℹ️  Note: Assuming 40-prompt limit per 5 hours (range is 10-40)"
echo "💡 Run this script anytime to check your status"