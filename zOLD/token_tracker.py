#!/usr/bin/env python3
"""
Claude Token Tracker - Terminal-based usage tracking for Claude Pro/Team plans
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
import argparse

# Configuration
DATA_FILE = Path.home() / '.claude_usage.json'
PLAN_LIMITS = {
    'pro': 150,  # Estimated monthly limit for Pro plan
    'team': 200,  # Estimated monthly limit for Team plan
    'custom': 100  # Default custom limit
}

class TokenTracker:
    def __init__(self):
        self.data = self.load_data()
    
    def load_data(self):
        """Load usage data from file"""
        if DATA_FILE.exists():
            try:
                with open(DATA_FILE, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                print("⚠️  Warning: Could not read existing data file. Starting fresh.")
        
        return {
            'plan': 'pro',
            'custom_limit': 150,
            'sessions': [],
            'created': datetime.now().isoformat()
        }
    
    def save_data(self):
        """Save usage data to file"""
        try:
            with open(DATA_FILE, 'w') as f:
                json.dump(self.data, f, indent=2)
        except IOError as e:
            print(f"❌ Error saving data: {e}")
    
    def add_session(self, cost, description=""):
        """Add a new session with cost"""
        session = {
            'cost': float(cost),
            'description': description,
            'timestamp': datetime.now().isoformat(),
            'date': datetime.now().strftime('%Y-%m-%d')
        }
        self.data['sessions'].insert(0, session)
        self.save_data()
        print(f"✅ Added session: ${cost:.2f} - {description}")
    
    def get_monthly_stats(self):
        """Calculate current month statistics"""
        now = datetime.now()
        current_month = now.strftime('%Y-%m')
        
        monthly_sessions = [
            s for s in self.data['sessions'] 
            if s['timestamp'].startswith(current_month)
        ]
        
        total_cost = sum(s['cost'] for s in monthly_sessions)
        session_count = len(monthly_sessions)
        avg_cost = total_cost / session_count if session_count > 0 else 0
        
        # Today's usage
        today = now.strftime('%Y-%m-%d')
        today_cost = sum(s['cost'] for s in monthly_sessions if s['date'] == today)
        
        return {
            'total_cost': total_cost,
            'session_count': session_count,
            'avg_cost': avg_cost,
            'today_cost': today_cost,
            'sessions': monthly_sessions
        }
    
    def get_projections(self, monthly_stats):
        """Calculate usage projections"""
        now = datetime.now()
        days_in_month = (datetime(now.year, now.month + 1, 1) - timedelta(days=1)).day
        current_day = now.day
        
        daily_avg = monthly_stats['total_cost'] / current_day if current_day > 0 else 0
        projected_monthly = daily_avg * days_in_month
        
        limit = PLAN_LIMITS.get(self.data['plan'], self.data.get('custom_limit', 150))
        remaining = max(0, limit - monthly_stats['total_cost'])
        
        if self.data['plan'] == 'pro':
            remaining_display = "Included in Pro"
        else:
            remaining_display = f"${remaining:.2f}"
        
        usage_percent = (monthly_stats['total_cost'] / limit) * 100 if limit > 0 else 0
        
        return {
            'projected_monthly': projected_monthly,
            'remaining': remaining,
            'remaining_display': remaining_display,
            'usage_percent': usage_percent,
            'limit': limit,
            'daily_avg': daily_avg
        }
    
    def display_status(self):
        """Display current usage status"""
        stats = self.get_monthly_stats()
        proj = self.get_projections(stats)
        
        print(f"\n🤖 Claude Usage Tracker - {datetime.now().strftime('%B %Y')}")
        print("=" * 50)
        
        # Plan info
        plan_name = self.data['plan'].title()
        if self.data['plan'] == 'custom':
            plan_name += f" (${self.data.get('custom_limit', 150)}/month)"
        print(f"📋 Plan: {plan_name}")
        
        # Usage stats
        print(f"💰 Monthly Usage: ${stats['total_cost']:.2f}")
        print(f"📊 Usage Percent: {proj['usage_percent']:.1f}%")
        print(f"🎯 Sessions This Month: {stats['session_count']}")
        print(f"📅 Today's Usage: ${stats['today_cost']:.2f}")
        print(f"📈 Daily Average: ${proj['daily_avg']:.2f}")
        print(f"🔮 Projected Monthly: ${proj['projected_monthly']:.2f}")
        print(f"💸 Estimated Remaining: {proj['remaining_display']}")
        
        # Progress bar
        bar_width = 30
        filled = int((proj['usage_percent'] / 100) * bar_width)
        bar = "█" * filled + "░" * (bar_width - filled)
        print(f"📊 Progress: [{bar}] {proj['usage_percent']:.1f}%")
        
        # Warnings
        if self.data['plan'] != 'pro':
            if proj['usage_percent'] > 90:
                print("\n⚠️  WARNING: Over 90% of estimated limit used!")
            elif proj['projected_monthly'] > proj['limit']:
                print(f"\n📈 NOTICE: Current rate projects ${proj['projected_monthly']:.2f} (over ${proj['limit']} limit)")
            elif proj['usage_percent'] > 75:
                print("\n📊 HEADS UP: Over 75% of estimated limit used")
    
    def display_recent_sessions(self, count=10):
        """Display recent sessions"""
        print(f"\n📝 Recent Sessions (Last {count}):")
        print("-" * 50)
        
        if not self.data['sessions']:
            print("No sessions recorded yet")
            return
        
        for session in self.data['sessions'][:count]:
            date = datetime.fromisoformat(session['timestamp']).strftime('%m/%d %H:%M')
            desc = session.get('description', 'No description')
            print(f"${session['cost']:6.2f} | {date} | {desc}")
    
    def set_plan(self, plan, custom_limit=None):
        """Set usage plan"""
        if plan not in PLAN_LIMITS and plan != 'custom':
            print(f"❌ Invalid plan. Choose from: {', '.join(PLAN_LIMITS.keys())}, custom")
            return
        
        self.data['plan'] = plan
        if plan == 'custom' and custom_limit:
            self.data['custom_limit'] = float(custom_limit)
        
        self.save_data()
        print(f"✅ Plan set to: {plan}")
        if plan == 'custom':
            limit = self.data.get('custom_limit', 150)
            print(f"📊 Custom limit: ${limit}/month")
    
    def export_data(self):
        """Export data to JSON file"""
        export_file = f"claude_usage_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        try:
            with open(export_file, 'w') as f:
                json.dump(self.data, f, indent=2)
            print(f"✅ Data exported to: {export_file}")
        except IOError as e:
            print(f"❌ Export failed: {e}")

def main():
    parser = argparse.ArgumentParser(description='Claude Token Usage Tracker')
    parser.add_argument('command', nargs='?', default='status', 
                       choices=['status', 'add', 'plan', 'sessions', 'export', 'help'],
                       help='Command to execute')
    parser.add_argument('--cost', '-c', type=float, help='Session cost to add')
    parser.add_argument('--description', '-d', default='', help='Session description')
    parser.add_argument('--plan', '-p', help='Set plan type (pro, team, custom)')
    parser.add_argument('--limit', '-l', type=float, help='Custom monthly limit')
    parser.add_argument('--count', '-n', type=int, default=10, help='Number of sessions to show')
    
    args = parser.parse_args()
    tracker = TokenTracker()
    
    if args.command == 'status':
        tracker.display_status()
    
    elif args.command == 'add':
        if args.cost is None:
            try:
                cost = float(input("💰 Enter session cost: $"))
                description = input("📝 Enter description (optional): ")
                tracker.add_session(cost, description)
            except (ValueError, KeyboardInterrupt):
                print("❌ Invalid input or cancelled")
        else:
            tracker.add_session(args.cost, args.description)
    
    elif args.command == 'plan':
        if args.plan:
            tracker.set_plan(args.plan, args.limit)
        else:
            current_plan = tracker.data['plan']
            print(f"Current plan: {current_plan}")
            if current_plan == 'custom':
                print(f"Custom limit: ${tracker.data.get('custom_limit', 150)}/month")
    
    elif args.command == 'sessions':
        tracker.display_recent_sessions(args.count)
    
    elif args.command == 'export':
        tracker.export_data()
    
    elif args.command == 'help':
        print("""
🤖 Claude Token Tracker Help

Commands:
  status              Show current usage statistics (default)
  add                 Add a new session cost
  plan                View or set plan type
  sessions            Show recent sessions
  export              Export data to JSON file
  help                Show this help message

Examples:
  python token_tracker.py                          # Show status
  python token_tracker.py add --cost 6.50          # Add session
  python token_tracker.py add -c 6.50 -d "Games"   # Add with description
  python token_tracker.py plan --plan pro          # Set to Pro plan
  python token_tracker.py plan --plan custom -l 200 # Set custom limit
  python token_tracker.py sessions --count 20      # Show 20 recent sessions

Quick add (interactive):
  python token_tracker.py add

Data is stored in: ~/.claude_usage.json
        """)

if __name__ == '__main__':
    main()