# PolyQuant System Status - March 17, 2026

## ✅ Actions Completed

### 1. Gen2/FreeForm Engine Status

**Engine: ALREADY ENABLED**

Current config:
```json
{
  "use_new_strategy": true,
  "use_gen2_engine": true,      // ✓ ENABLED
  "use_new_architecture": true  // ✓ ENABLED
}
```

**Active Code Path:**
```
main.rs → new_architecture.rs → strategy_task.rs → gen2_engine/consensus.rs
```

### 2. Account Reset

| Before | After |
|--------|-------|
| Balance: $8,268.99 | **$10,000.00** ✓ |
| Initial: $10,000.00 | $10,000.00 |

**Stats Reset:**
- PnL: $0 (starting fresh)
- Win Rate: N/A (awaiting new trades)
- Trade Count: 0 (new trades only)

---

## 🔍 Critical Discovery: No LLM Integration

### What the Gen2 Engine Actually Does

The Gen2/FreeForm engine is **purely technical** - it does NOT use LLM:

```rust
// Gen2 Decision Components:
1. Mid Regime: 15m MA7 slope analysis
2. Short Regime: HMA-14 with velocity (ROC)
3. Jitter Guard: BIPS-based noise detection  
4. OBI Filter: Order Book Imbalance validation
5. Consensus: Weighted score combining above
```

**NO LLM integration exists in the current codebase.**

### Decision Flow

```
┌─────────────────┐
│  Market Data    │
│  (Price, OB)    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Strategy Task  │
│  (t=0 trigger)  │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Gen2 Consensus │ ← Technical indicators only
│  Engine         │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Trade Signal   │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Executor Task  │ ← Kelly sizing
└────────┬────────┘
         ▼
┌─────────────────┐
│  Position Open  │
└─────────────────┘
```

### If You Want LLM FreeForm

The LLM integration mentioned in your earlier notes appears to be:
1. **Not yet implemented** in the current codebase, OR
2. **In a separate component** (e.g., Python trigger script), OR  
3. **Removed** during refactoring

To add LLM FreeForm, you would need:
- An LLM decision feed (API endpoint or file)
- Integration point in `strategy_task.rs` or `gen2_engine/consensus.rs`
- Override logic for technical indicators

---

## 📊 Current System Architecture

### Active Components

| Component | Status | Notes |
|-----------|--------|-------|
| Gen2 Consensus | ✓ Active | HMA + slope + OBI |
| Kelly Engine | ✓ Active | Position sizing |
| Executor Task | ✓ Active | Trade execution |
| WebSocket Tasks | ✓ Active | Price + order book |
| LLM FreeForm | ✗ Not Present | Technical only |

### Data Flow

1. **WebSocket Tasks** → Price + Order Book → Shared State
2. **Strategy Task** (every 5m at t=0) → Gen2 Analysis
3. **Gen2 Engine** → Score + Action (BullGo/BearGo/Neutral)
4. **Executor Task** → Kelly sizing → Position open
5. **Exit Task** → Position close at block end

---

## 🔄 Reset Script Created

Location: `/root/.openclaw/workspace/openclaw-polytrader/skills/poly-hft-pro/reset_account.sh`

Usage:
```bash
./reset_account.sh
```

What it does:
- Resets current_balance = initial_balance ($10,000)
- Preserves historical trade data for reference

---

## ⚠️ Important Notes

### 1. Database Query Fix

When querying stats, **always filter for primary positions**:

```sql
-- ✓ CORRECT - Primary only
SELECT * FROM positions 
WHERE position_id LIKE '%primary%' 
  AND status = 'CLOSED'
ORDER BY entry_time_ms DESC;

-- ✗ WRONG - Includes hedge positions (distorts stats)
SELECT * FROM positions WHERE status = 'CLOSED';
```

### 2. Historical Data

- Old trades (including hedge positions) preserved in database
- New trades will use `pos_gen2_*_primary` naming
- Hedge positions no longer created (hedge_ratio: 0.0)

### 3. Next Steps

To verify system is working:
1. Check logs for "🚀 Starting NEW ARCHITECTURE trading..."
2. Verify Gen2 decisions at t=0 (every 5 minutes)
3. Monitor Telegram notifications for trade signals

---

## 📈 Expected Behavior

With Gen2 engine active:
- **Mid Regime**: 15m MA7 slope > ±25° for trend detection
- **Short Regime**: HMA-14 velocity for timing
- **Jitter Guard**: Max 10 BIPS noise threshold
- **OBI Filter**: ±20% order book imbalance required
- **Position Sizing**: Kelly criterion (max 5% of balance)

**No LLM involvement** - purely technical indicators.

---

## 📝 Summary

| Item | Status |
|------|--------|
| Gen2 Engine | ✓ Already enabled |
| Account Reset | ✓ $10,000.00 |
| Stats Reset | ✓ Fresh start |
| LLM FreeForm | ✗ Not present |
| Hedge Positions | ✗ Disabled |

**Bottom Line:** The system is now running with a clean slate ($10k), but there's no LLM integration. The "FreeForm" decisions are purely technical (HMA + slopes + OBI).
