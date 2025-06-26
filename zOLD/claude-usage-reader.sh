#!/usr/bin/env python3
"""
Claude Pro Usage Tracker - Shows remaining prompts for Claude Pro subscription
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path

# Path to Claude's actual config file
CLAUDE_CONFIG = Path.home() / '.claude.json'

# Claude Pro limits (newly released subscription plan)
CLAUDE_PRO_DAILY_PROMPTS = 30  # Conservative estimate, actual range 10-40
CLAUDE_PRO_AVG_SENTENCES = 45  # Average sentences per prompt

def load_claude_data():
    """Load Claude's actual usage data"""
    if not CLAUDE_CONFIG.exists():
        print("❌ Claude config file not found. Make sure Claude Code is installed.")
        return None
    
    try:
        with open(CLAUDE_CONFIG, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        print(f"❌ Error reading Claude config: {e}")
        return None

def format_tokens(tokens):
    """Format token count with commas"""
    return f"{tokens:,}" if tokens else "0"

def analyze_project_usage(project_path, project_data):
    """Analyze usage for a specific project"""
    print(f"\n📁 Project: {project_path}")
    print("=" * 60)
    
    # Last session metrics
    if 'lastCost' in project_data:
        print(f"💰 Last Session Cost: ${project_data['lastCost']:.4f}")
    
    if 'lastTotalInputTokens' in project_data:
        input_tokens = project_data['lastTotalInputTokens']
        output_tokens = project_data.get('lastTotalOutputTokens', 0)
        cache_creation = project_data.get('lastTotalCacheCreationInputTokens', 0)
        cache_read = project_data.get('lastTotalCacheReadInputTokens', 0)
        
        total_tokens = input_tokens + output_tokens + cache_creation + cache_read
        
        print(f"🔤 Last Session Tokens:")
        print(f"   Input: {format_tokens(input_tokens)}")
        print(f"   Output: {format_tokens(output_tokens)}")
        print(f"   Cache Creation: {format_tokens(cache_creation)}")
        print(f"   Cache Read: {format_tokens(cache_read)}")
        print(f"   Total: {format_tokens(total_tokens)}")
    
    if 'lastAPIDuration' in project_data:
        duration_ms = project_data['lastAPIDuration']
        print(f"⏱️  Last API Duration: {duration_ms:,}ms ({duration_ms/1000:.2f}s)")
    
    # Command history count
    history = project_data.get('history', [])
    print(f"📝 Commands This Session: {len(history)}")
    
    if history:
        print(f"\n📋 Recent Commands:")
        for i, cmd in enumerate(history[-5:], 1):  # Show last 5 commands
            display = cmd.get('display', '').strip()
            if len(display) > 60:
                display = display[:57] + "..."
            print(f"   {i}. {display}")

def estimate_usage_limits():
    """Estimate usage based on known patterns"""
    print(f"\n🤖 Claude Pro Plan Estimates:")
    print("=" * 40)
    print("📊 Pro plans include Claude Code usage")
    print("💡 Typical patterns:")
    print("   • Light usage: ~50-100 commands/day")
    print("   • Medium usage: ~100-300 commands/day") 
    print("   • Heavy usage: ~300+ commands/day")
    print("\n💰 Cost estimates (if you were paying per token):")
    print("   • Input tokens: ~$0.003 per 1K tokens")
    print("   • Output tokens: ~$0.015 per 1K tokens")
    print("   • Cache creation: ~$0.0075 per 1K tokens")
    print("   • Cache reads: ~$0.0003 per 1K tokens")

def main():
    data = load_claude_data()
    if not data:
        return
    
    print("🤖 Claude Code Usage Analysis")
    print("=" * 40)
    
    # Basic info
    print(f"👤 User: {data.get('oauthAccount', {}).get('emailAddress', 'Unknown')}")
    print(f"🚀 Number of Startups: {data.get('numStartups', 0)}")
    print(f"📊 Prompt Queue Uses: {data.get('promptQueueUseCount', 0)}")
    
    if 'firstStartTime' in data:
        first_start = datetime.fromisoformat(data['firstStartTime'].replace('Z', '+00:00'))
        print(f"🕐 First Started: {first_start.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Project usage
    projects = data.get('projects', {})
    if projects:
        print(f"\n📁 Active Projects: {len(projects)}")
        
        for project_path, project_data in projects.items():
            analyze_project_usage(project_path, project_data)
    
    estimate_usage_limits()
    
    # Quick usage summary
    total_commands = sum(len(p.get('history', [])) for p in projects.values())
    total_cost = sum(p.get('lastCost', 0) for p in projects.values())
    
    print(f"\n📈 Session Summary:")
    print(f"   Total Commands: {total_commands}")
    print(f"   Total Last Session Cost: ${total_cost:.4f}")
    
    print(f"\n💡 Pro Tip: Use '/cost' in Claude Code for real-time session costs!")

if __name__ == '__main__':
    main()