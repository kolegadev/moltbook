#!/usr/bin/env python3
"""
Self-Improving Agent Integration for KimiClaw Core
Continuous improvement tracking for the main agent personality
"""

import sys
sys.path.insert(0, '/root/.openclaw/workspace/skills/xiucheng-self-improving-agent')

from self_improving import SelfImprovingAgent
from datetime import datetime

# Initialize core agent self-improvement
sia = SelfImprovingAgent(workspace="/root/.openclaw/workspace")

def log_core_improvement(insight: str, category: str = "general"):
    """Log an improvement for the core KimiClaw agent."""
    sia.log_improvement(insight, category)
    print(f"[Core-SIA] Logged: {insight}")

def analyze_session(conversation: str, feedback: str = None):
    """Analyze a conversation session."""
    analysis = sia.analyze_conversation(conversation, feedback)
    
    # Log any identified improvements
    for improvement in analysis.get("improvements", []):
        sia.log_improvement(improvement, category="auto-analysis")
    
    return analysis

def get_weekly_report():
    """Generate weekly self-improvement report."""
    return sia.generate_weekly_report()

def get_stats():
    """Get improvement statistics."""
    return sia.get_improvement_stats()

def suggest_soul_updates():
    """Get suggestions for SOUL.md updates."""
    return sia.suggest_soul_updates()

# Auto-log initialization
if __name__ == "__main__":
    print("🔄 KimiClaw Core Self-Improving Agent initialized")
    stats = get_stats()
    print(f"   Improvement log exists: {stats['log_exists']}")
    print(f"   Total entries: {stats['total_entries']}")
    print(f"   SOUL.md exists: {stats['soul_exists']}")
