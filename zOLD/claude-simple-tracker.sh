#!/bin/bash

# Simple Claude Code Usage Tracker

current_epoch=$(date +%s)
window_start_epoch=$((current_epoch - (10 * 3600)))

# Find session files
all_session_files=$(find ~/.claude/projects -name "*.jsonl" -type f 2>/dev/null)
session_files=""

for file in $all_session_files; do
    file_mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
    if [ "$file_mtime" -gt "$window_start_epoch" ]; then
        session_files="$session_files $file"
    fi
done

if [ -z "$session_files" ]; then
    echo "No active session"
    exit 0
fi

# Get all message timestamps to find session boundaries
all_messages=()
for session_file in $session_files; do
    while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '.timestamp')
        if [ "$timestamp" != "null" ] && [ "$timestamp" != "" ]; then
            clean_timestamp=$(echo "$timestamp" | sed 's/\.[0-9]*Z$/Z/')
            msg_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_timestamp" +%s 2>/dev/null)
            if [ "$msg_epoch" != "" ]; then
                all_messages+=("$msg_epoch")
            fi
        fi
    done < <(grep '"type":"user"' "$session_file" | grep -v '"isMeta":true')
done

# Sort and find current session start
IFS=$'\n' sorted=($(sort -n <<< "${all_messages[*]}"))
session_start=${sorted[0]}

for ((i=1; i<${#sorted[@]}; i++)); do
    gap=$((${sorted[$i]} - ${sorted[$((i-1))]}))
    if [ $gap -gt 18000 ]; then  # 5 hour gap
        session_start=${sorted[$i]}
    fi
done

# Count prompts and tokens in current session
total_prompts=0
total_input=0
total_output=0

for session_file in $session_files; do
    # Count prompts in current session
    while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '.timestamp')
        if [ "$timestamp" != "null" ] && [ "$timestamp" != "" ]; then
            clean_timestamp=$(echo "$timestamp" | sed 's/\.[0-9]*Z$/Z/')
            msg_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_timestamp" +%s 2>/dev/null)
            if [ "$msg_epoch" != "" ] && [ "$msg_epoch" -ge "$session_start" ]; then
                total_prompts=$((total_prompts + 1))
            fi
        fi
    done < <(grep '"type":"user"' "$session_file" | grep -v '"isMeta":true')
    
    # Count tokens in current session
    while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '.timestamp')
        if [ "$timestamp" != "null" ] && [ "$timestamp" != "" ]; then
            clean_timestamp=$(echo "$timestamp" | sed 's/\.[0-9]*Z$/Z/')
            msg_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_timestamp" +%s 2>/dev/null)
            if [ "$msg_epoch" != "" ] && [ "$msg_epoch" -ge "$session_start" ]; then
                input=$(echo "$line" | jq -r '.usage.input_tokens // 0')
                output=$(echo "$line" | jq -r '.usage.output_tokens // 0')
                cache_create=$(echo "$line" | jq -r '.usage.cache_creation_input_tokens // 0')
                cache_read=$(echo "$line" | jq -r '.usage.cache_read_input_tokens // 0')
                
                total_input=$((total_input + input + cache_create + cache_read))
                total_output=$((total_output + output))
            fi
        fi
    done < <(grep '"usage":' "$session_file")
done

# Calculate reset time (5 hours from session start hour)
session_hour=$(( (session_start / 3600) * 3600 ))
reset_time=$((session_hour + (5 * 3600)))

# Display
input_k=$((total_input / 1000))
output_k=$((total_output / 1000))
echo "📊 Usage: $total_prompts prompts | ${input_k}k in + ${output_k}k out tokens"

if [ $current_epoch -lt $reset_time ]; then
    remaining=$((reset_time - current_epoch))
    hours=$((remaining / 3600))
    minutes=$(((remaining % 3600) / 60))
    reset_display=$(date -r $reset_time '+%I:%M %p')
    echo "⏰ Resets: $reset_display (${hours}h ${minutes}m left)"
else
    echo "🔄 Session expired"
fi