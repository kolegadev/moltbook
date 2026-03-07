#!/usr/bin/env python3
"""
Unified Self-Improving Agent Interface
Access both Core KimiClaw and PolyQuant improvement tracking
"""

import sys
sys.path.insert(0, '/root/.openclaw/workspace/skills')
sys.path.insert(0, '/root/.openclaw-trading/skills/poly-quant/scripts')

from self_improving_core import (
    log_core_improvement, 
    analyze_session, 
    get_weekly_report as get_core_report,
    get_stats as get_core_stats
)

from self_improving_polyquant import (
    log_polyquant_improvement,
    analyze_research_session,
    log_strategy_insight,
    log_backtest_result,
    get_polyquant_report,
    get_stats as get_polyquant_stats
)

class UnifiedSelfImprovingAgent:
    """Unified interface for both Core and PolyQuant self-improvement."""
    
    @staticmethod
    def log_core(insight: str, category: str = "general"):
        """Log improvement for Core KimiClaw."""
        log_core_improvement(insight, category)
    
    @staticmethod
    def log_polyquant(insight: str, category: str = "quant-research"):
        """Log improvement for PolyQuant."""
        log_polyquant_improvement(insight, category)
    
    @staticmethod
    def log_strategy(strategy_name: str, insight: str):
        """Log strategy insight for PolyQuant."""
        log_strategy_insight(strategy_name, insight)
    
    @staticmethod
    def log_backtest(strategy: str, result: str, improvement: str):
        """Log backtest learning for PolyQuant."""
        log_backtest_result(strategy, result, improvement)
    
    @staticmethod
    def core_report():
        """Get Core KimiClaw weekly report."""
        return get_core_report()
    
    @staticmethod
    def polyquant_report():
        """Get PolyQuant improvement report."""
        return get_polyquant_report()
    
    @staticmethod
    def all_stats():
        """Get stats for both systems."""
        return {
            "core": get_core_stats(),
            "polyquant": get_polyquant_stats()
        }
    
    @staticmethod
    def full_report():
        """Generate comprehensive report for both."""
        return f"""
# 🔄 Unified Self-Improvement Report

## Core KimiClaw Agent
{get_core_report()}

---

## PolyQuant Project
{get_polyquant_report()}
"""

# Global instance for easy access
usia = UnifiedSelfImprovingAgent()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Unified Self-Improving Agent")
    parser.add_argument("--core-log", help="Log core improvement")
    parser.add_argument("--polyquant-log", help="Log PolyQuant improvement")
    parser.add_argument("--strategy", help="Log strategy insight (requires --name)")
    parser.add_argument("--name", help="Strategy name")
    parser.add_argument("--report", choices=["core", "polyquant", "full"], 
                       help="Generate report")
    parser.add_argument("--stats", action="store_true", help="Show stats")
    
    args = parser.parse_args()
    
    if args.core_log:
        usia.log_core(args.core_log)
    elif args.polyquant_log:
        usia.log_polyquant(args.polyquant_log)
    elif args.strategy and args.name:
        usia.log_strategy(args.name, args.strategy)
    elif args.report == "core":
        print(usia.core_report())
    elif args.report == "polyquant":
        print(usia.polyquant_report())
    elif args.report == "full":
        print(usia.full_report())
    elif args.stats:
        import json
        print(json.dumps(usia.all_stats(), indent=2))
    else:
        print("🔄 Unified Self-Improving Agent")
        print("   Use --help for options")
        stats = usia.all_stats()
        print(f"\n   Core entries: {stats['core']['total_entries']}")
        print(f"   PolyQuant entries: {stats['polyquant']['total_entries']}")
