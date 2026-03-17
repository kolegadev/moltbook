# PolyQuant Trade Retrospective - March 17, 2026

## Executive Summary

**CRITICAL FINDINGS:**
1. **Win Rate: 36%** - SHOCKINGLY BAD performance
2. **YES Trade Bias: 72% YES vs 28% NO** - Severe imbalance
3. **YES Win Rate: 22.2%** vs **NO Win Rate: 71.4%** - YES trades are failing dramatically
4. **Total P&L: -$5,359.16** over last 25 trades

---

## Data Analysis

### Last 25 Trades Breakdown

| Metric | Value |
|--------|-------|
| Total Trades | 25 |
| Wins | 9 (36%) |
| Losses | 16 (64%) |
| **YES Trades** | **18 (72%)** |
| **NO Trades** | **7 (28%)** |
| YES Win Rate | 22.2% (4/18) |
| NO Win Rate | 71.4% (5/7) |
| Total P&L | -$5,359.16 |
| YES P&L | -$5,661.96 |
| NO P&L | +$302.80 |

### Streak Analysis
- **Max Consecutive YES**: 9 trades
- **Max Consecutive NO**: 1 trade
- **Recent Streak**: 3 consecutive YES trades

---

## Observation 1: Trade Choices Are SHOCKINGLY BAD

### The Numbers Don't Lie
- **Overall win rate: 36%** - This is worse than random chance
- **YES trades win only 22.2% of the time** - This is catastrophic
- **NO trades win 71.4% of the time** - Actually decent performance

### Root Cause Analysis

The LLM decision engine is systematically making poor YES trade decisions. Possible causes:

1. **Bull Market Bias**: System may be over-optimistic in bull regimes, taking YES trades when market is actually reversing
2. **Confirmation Bias**: Looking for confirming signals for YES trades while ignoring disconfirming evidence
3. **Late Entry**: Entering YES trades after the move has already happened
4. **Trend Exhaustion**: Taking YES trades at trend tops when momentum is fading

### Evidence
Looking at the trade log:
- Multiple consecutive YES losses during what appears to be ranging or reversing conditions
- Large individual losses on YES trades (-$400 to -$600 each)
- NO trades showing consistent profitability

---

## Observation 2: Severe YES/NO Bias - NOT Normal Distribution

### The Bias Is Extreme
- **72% YES trades vs 28% NO trades**
- In a fair system with no bias, we'd expect closer to 50/50
- This suggests the decision algorithm has a structural preference for YES

### Market Context
User noted this occurred **during BULL regime** - which makes the YES bias even more concerning:
- If market is truly bullish, YES trades should have higher win rate
- Instead, YES trades performed WORSE in bull conditions
- This suggests the system is misidentifying "bull" conditions

### Statistical Significance
11 consecutive NO trades would be unusual (p < 0.001), but we see the opposite:
- **9 consecutive YES trades** at one point
- **Recent streak of 3 YES trades**
- NO trades rarely appear consecutively (max 1)

This is NOT random distribution - it's systematic bias.

---

## The Paradox: NO Trades Work, YES Trades Don't

Despite heavy bias toward YES:
- YES P&L: **-$5,661.96** (catastrophic)
- NO P&L: **+$302.80** (profitable)

**The system is doing the opposite of what works.**

---

## Recommendations for Decision Prompt Refinement

### 1. Add YES Trade Discipline

Current prompt likely encourages YES trades. Need to add:
```
CRITICAL: Before taking a YES trade, you MUST verify:
- Is momentum actually increasing? (not just "bull regime")
- Are we entering early in the move, not late?
- Is there evidence of trend exhaustion that you're ignoring?

If you have ANY doubt, prefer NO_TRADE over YES.
```

### 2. Force NO Trade Consideration

The bias suggests the prompt may not give equal weight to NO scenarios:
```
MANDATORY: For every decision, explicitly state:
1. Why YES might be wrong
2. Why NO might be right
3. What would make you choose NO over YES

You cannot default to YES without strong counter-argument consideration.
```

### 3. Add Loss Aversion for YES

Given the terrible YES track record:
```
HISTORICAL CONTEXT: Recent YES trades have 22% win rate with -$5,600+ losses.
Recent NO trades have 71% win rate with +$300 gains.

You should be EXTREMELY skeptical of YES signals until this trend reverses.
Require 3x stronger evidence for YES vs NO.
```

### 4. Fix the "Bull Regime" Classification

The fact that YES trades failed during BULL regime suggests:
- The regime classifier is broken
- It's calling things "bull" that aren't actually bullish
- Need to verify regime signals against actual price action

Add to prompt:
```
REGIME VERIFICATION: Before trusting a "BULL" classification:
- Check if price has actually been moving up
- Check if YES trades in recent similar conditions have won or lost
- If recent YES trades lost, the "bull" signal may be wrong
```

### 5. Position Sizing Fix

Given the poor YES performance:
```
POSITION SIZING RULE:
- NO trades: Normal position sizing (1-5% based on conviction)
- YES trades: HALVE the position size (0.5-2.5%) due to poor historical performance
- Only increase YES sizing after win rate improves above 50%
```

---

## Immediate Actions Required

1. **Stop taking YES trades** until prompt is fixed
2. **Review regime classification logic** - it's clearly broken
3. **Add trade outcome tracking to LLM context** - let it see its poor YES performance
4. **Consider manual override** - require human approval for YES trades
5. **Investigate whether PIN detection is causing false YES signals**

---

## Conclusion

The data is unambiguous: **The current decision system has a catastrophic YES bias that is destroying profitability.**

- YES trades: 22% win rate, -$5,600 loss
- NO trades: 71% win rate, +$300 profit

The system is literally doing the opposite of what works. This needs immediate intervention before more capital is lost.

**Priority: CRITICAL**
