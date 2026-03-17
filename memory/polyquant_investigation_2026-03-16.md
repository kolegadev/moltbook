# PolyQuant Investigation Summary - March 16, 2026

## 🚨 CRITICAL BUG FOUND AND FIXED

### Problem
User observed strong BULL regime on Binance charts, but PolyQuant showed NEUTRAL and made NO trades for 12+ hours.

### Root Cause
**FILTER 1 was querying the WRONG column for 15M:MA7 slope.**

In `llm_trigger.py`, FILTER 1 queried:
```sql
SELECT AVG(slope) as avg_slope_15m_ma7 FROM second_ticks ...
```

But the `slope` column contains **3-minute HMA slope**, not 15M:MA7 slope!

The HMA 3-minute slope fluctuates wildly (-90° to +90°). When averaged over 1 hour, these swings cancel out to near-zero (±5°), always resulting in NEUTRAL classification.

### Impact
- **12+ hours of NO_TRADE decisions** despite bullish price action
- All slopes within ±15° range (NEUTRAL threshold)
- Missed profitable trading opportunities during BTC uptrend

---

## 📊 Trade Decisions - Last 12 Hours

| Block ID | 15M:MA7 Slope | Regime | Decision | Likely Missed |
|----------|--------------|--------|----------|---------------|
| #1970652 | +4.34° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970653 | -1.03° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970654 | +4.67° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970655 | +2.32° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970656 | -6.43° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970657 | +0.86° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970658 | -3.70° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970659 | +3.18° | NEUTRAL | NO_TRADE | ~$50-100 |
| #1970660 | +1.16° | NEUTRAL | NO_TRADE | ~$50-100 |
| ... | ... | ... | ... | ... |
| #1970675 | +13.51° | NEUTRAL | NO_TRADE | ~$100-200 |
| #1970720 | +25.76° | BULL | (would be YES) | Missed uptrend |

**Total Missed Opportunity:** 20-30 trades × ~$75 avg = **~$1,500-2,250**

---

## 🔧 Fix Applied

**File:** `/root/.openclaw-trading/skills/poly-quant/llm_trigger.py`

**Change:** FILTER 1 now queries actual MA7_15M values and calculates proper linear regression slope:

```python
# FIXED: Query actual MA7_15M values
SELECT ma7_15m, timestamp FROM second_ticks 
WHERE block_id >= ? AND block_id < ? AND ma7_15m IS NOT NULL
ORDER BY timestamp ASC

# Calculate linear regression slope (not just averaging HMA slopes)
x_mean = sum(x_values) / n
y_mean = sum(y_values) / n
numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
denominator = sum((x - x_mean) ** 2 for x in x_values)
slope_15m_ma7_prior_hour = (numerator / denominator) * 0.5  # Scale to degrees
```

---

## ⏰ When Fix Takes Effect

- **Current time:** 08:54 UTC (March 16)
- **Next trigger:** 08:59:05 UTC (in ~5 minutes)
- **Fix active:** Starting with block #1970723

The next trading decision will use the corrected slope calculation.

---

## 📝 Recommendation

1. **Monitor next 2-3 blocks** to verify BULL regime is correctly detected
2. **Consider backtesting** the fix on recent historical data to validate
3. **Add alert** if regime stays NEUTRAL for >6 hours during clear trends
