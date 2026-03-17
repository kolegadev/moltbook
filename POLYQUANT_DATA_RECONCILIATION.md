# PolyQuant Database vs UI Data Reconciliation Report

## Executive Summary

**ROOT CAUSE IDENTIFIED:** The database contains BOTH primary AND hedge positions, while the UI correctly displays only PRIMARY positions. My initial query inadvertently included hedge positions, which inverted the trade statistics.

## The Mismatch Explained

### What I Found

**Database Query (WRONG - included hedges):**
- Total positions: 71
- YES: 41 trades | NO: 30 trades
- YES win rate: 22% | NO win rate: 71%

**UI Data (CORRECT - primary only):**
- Total trades: 32 (most recent)
- YES: 7 trades (22%) | NO: 25 trades (78%)
- YES win rate: 57% | NO win rate: 36%

### Why The Database Has Extra Data

The system previously created **hedge positions** alongside primary positions. For every trade:
- **Primary position**: The actual trade decision (YES or NO)
- **Hedge position**: Opposite side for risk management (automatically created)

Example from database:
```
Block 1773552600:
  - pos_gen2_1773552600_primary | YES | -$621.55 (LOSS)
  - pos_gen2_1773552600_hedge   | NO  | +$70.29 (WIN)
```

When querying ALL positions, hedge positions (opposite side) were included, completely distorting the statistics.

## Code Path Analysis

### Multiple Trading Systems Present

1. **new_strategy_trading.rs** (LEGACY - currently active)
   - Created BOTH primary AND hedge positions
   - Last hedge created: March 15, 2026
   - Position IDs: `pos_gen2_*_primary`, `pos_gen2_*_hedge`

2. **executor_task.rs** (GEN2 - currently active)
   - Creates ONLY primary positions
   - Position IDs: `pos_gen2_*_primary`
   - No hedge positions

3. **gen2_engine.rs** (GEN2 decision engine)
   - Kelly-based sizing
   - Hedge explicitly disabled: `hedge_size: 0.0`

### Current Configuration

```rust
// From config.rs - CURRENT SETTINGS:
use_new_architecture: false  // DISABLED
use_gen2_engine: false       // DISABLED
use_new_strategy: true       // ENABLED (legacy)
hedge_ratio: 0.0             // 0% hedge (disabled)
```

**Critical Finding:** The system is running the **legacy new_strategy_trading** path, NOT the Gen2 engine the user expects.

### Position ID Patterns

| Pattern | Source | Status |
|---------|--------|--------|
| `pos_gen2_*_primary` | gen2_executor | Currently active |
| `pos_gen2_*_hedge` | legacy new_strategy | Stopped March 15 |
| `pos_new_*_primary` | legacy new_strategy | Older trades |
| `pos_new_*_hedge` | legacy new_strategy | Older trades |

## Corrected Trade Analysis (Primary Only)

### Last 32 Trades (UI Data - CONFIRMED CORRECT)

| Metric | Value |
|--------|-------|
| **YES Trades** | 7 (22%) |
| **NO Trades** | 25 (78%) |
| **YES Win Rate** | 57% (4/7) |
| **NO Win Rate** | 36% (9/25) |
| **Total P&L** | -$1,422 |
| **YES P&L** | +$70 |
| **NO P&L** | -$1,492 |
| **Current Streak** | **11 consecutive NO trades** |

### Key Observations (CORRECTED)

**1. Trade Choices Are Poor - NO TRADES SPECIFICALLY**
- NO trades win only 36% of the time
- NO trades have lost $1,492 while YES trades gained $70
- The system is systematically wrong on NO decisions

**2. Severe Bias TOWARD NO Trades**
- 78% NO vs 22% YES is extreme imbalance
- **11 consecutive NO trades** at the end
- This defies normal distribution

**3. The Paradox Inverted**
- YES trades are actually PROFITABLE (+$70, 57% win rate)
- NO trades are DESTROYING capital (-$1,492, 36% win rate)
- System has NO bias, not YES bias as initially thought

## Critical Issue: Wrong Code Path Active

### The Problem

The user expects **LLM FreeForm** (Gen2 engine) to be making decisions, but the system is running the **legacy new_strategy** code path.

**Evidence:**
1. Config shows: `use_gen2_engine: false`
2. Config shows: `use_new_strategy: true`
3. Position IDs match `pos_gen2_*` pattern from executor_task
4. Main.rs logic:
```rust
if config.use_new_architecture {
    new_architecture::run_new_architecture().await  // NOT ACTIVE
} else {
    run_new_strategy_trading().await  // CURRENTLY ACTIVE
}
```

### Where Decisions Are Actually Made

Current active path: `new_strategy_trading.rs`
- Uses L1 (15m MA7 slope) regime detection
- Uses L2 (1m MA7 slope) confirmation
- NOT using LLM FreeForm

Expected path: `gen2_engine.rs` via `executor_task.rs`
- Uses Kelly engine with L1 filter
- Should use LLM FreeForm decisions
- Hedge disabled

## Recommendations

### Immediate Actions

1. **Enable Gen2 Engine** (if LLM FreeForm is desired):
   ```json
   {
     "use_gen2_engine": true,
     "use_new_strategy": false,
     "use_new_architecture": true
   }
   ```

2. **Verify LLM FreeForm Integration**:
   - Check if LLM decision feed is connected to executor_task
   - Ensure `gen2_engine.rs` receives LLM decisions
   - Verify no legacy filters are overriding LLM

3. **Database Query Fix**:
   ```sql
   -- Always filter for primary positions only
   SELECT * FROM positions 
   WHERE position_id LIKE '%primary%' 
     AND status = 'CLOSED'
   ORDER BY entry_time_ms DESC;
   ```

4. **Clean Up Legacy Data** (optional):
   - Hedge positions are noise for analysis
   - Consider archiving or marking hedge positions

### Decision Prompt Refinement (Based on CORRECTED Data)

The actual problem is **NO trade bias**, not YES bias:

```
CRITICAL OBSERVATION: Recent NO trades have 36% win rate with -$1,492 losses.
Recent YES trades have 57% win rate with +$70 gains.

The system is systematically biased toward NO trades that fail.

MANDATORY CHECK: Before taking a NO trade:
1. Is bearish momentum actually confirmed?
2. Are you entering early, not late in the move?
3. Could this be a bear trap or reversal?

REQUIRE 2x stronger evidence for NO vs YES.
```

## Summary

| Issue | Finding |
|-------|---------|
| Database vs UI mismatch | Hedge positions included in query |
| Active code path | Legacy new_strategy (not Gen2) |
| Actual trade bias | 78% NO (not YES) |
| Winning side | YES trades (57% win rate) |
| Losing side | NO trades (36% win rate) |
| Current streak | 11 consecutive NO trades |

**The user's instinct was correct** - the UI data is accurate. The database query was including hedge positions that distorted the analysis. The real issue is a severe NO trade bias with poor NO trade performance.
