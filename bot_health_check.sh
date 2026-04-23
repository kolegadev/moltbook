#!/usr/bin/env bash
# Health check for all 3 Polymarket BTC trading bots
# v4.3-final, v4.4-MaxPnL, v4.5-MaxPnL, v4.6-MaxPnL, v4.7-MaxPnL
# Run every minute via cron

BASE_DIR="/root/polymarket-BTC-momentum-trader"
LOG_DIR="$BASE_DIR/logs"
DATA_DIR="$BASE_DIR/data"
HEALTH_LOG="/tmp/bot_health_check.log"
NOW=$(date +%s)

# ─── Config per bot ──────────────────────────────────────────────
declare -A BOT_NAME
BOT_NAME[v43]="v4.3-final"
BOT_NAME[v44]="v4.4-MaxPnL"
BOT_NAME[v45]="v4.5-MaxPnL"
BOT_NAME[v46]="v4.6-MaxPnL"
BOT_NAME[v47]="v4.7-MaxPnL"
BOT_NAME[v48]="v4.8-Hybrid"

declare -A BOT_SCRIPT
BOT_SCRIPT[v43]="scripts/unified_trader.py"
BOT_SCRIPT[v44]="scripts/v4.4-MaxPnL.py"
BOT_SCRIPT[v45]="scripts/v4.5-MaxPnL.py"
BOT_SCRIPT[v46]="scripts/v4.6-MaxPnL.py"
BOT_SCRIPT[v47]="scripts/v4.7-MaxPnL.py"
BOT_SCRIPT[v48]="scripts/v4.8-MaxPnL-Hybrid.py"

declare -A BOT_ARGS
BOT_ARGS[v43]="--db data/predictor.db --trade-db data/unified_v4.db --strategy MOMENTUM_V1"
BOT_ARGS[v44]="--trade-db data/v4_4_maxpnl.db --strategy MAXPNL_V44"
BOT_ARGS[v45]="--trade-db data/v4_5_maxpnl.db --strategy MAXPNL_V45"
BOT_ARGS[v46]="--trade-db data/v4_6_maxpnl.db --strategy MAXPNL_V46"
BOT_ARGS[v47]="--trade-db data/v4_7_maxpnl.db --strategy MAXPNL_V47"
BOT_ARGS[v48]="--trade-db data/v4_8_hybrid.db"

declare -A BOT_LOG
BOT_LOG[v43]="$LOG_DIR/unified_trader.log"
BOT_LOG[v44]="$LOG_DIR/v4_4_maxpnl.log"
BOT_LOG[v45]="$LOG_DIR/v4_5_maxpnl.log"
BOT_LOG[v46]="$LOG_DIR/v4_6_maxpnl.log"
BOT_LOG[v47]="$LOG_DIR/v4_7_maxpnl.log"
BOT_LOG[v48]="$LOG_DIR/v4_8_hybrid.log"

declare -A BOT_DB
BOT_DB[v43]="$DATA_DIR/unified_v4.db"
BOT_DB[v44]="$DATA_DIR/v4_4_maxpnl.db"
BOT_DB[v45]="$DATA_DIR/v4_5_maxpnl.db"
BOT_DB[v46]="$DATA_DIR/v4_6_maxpnl.db"
BOT_DB[v47]="$DATA_DIR/v4_7_maxpnl.db"
BOT_DB[v48]="$DATA_DIR/v4_8_hybrid.db"

declare -A BOT_PID_PATTERN
BOT_PID_PATTERN[v43]="unified_trader.py.*MOMENTUM_V1"
BOT_PID_PATTERN[v44]="v4.4-MaxPnL.py.*v4_4_maxpnl"
BOT_PID_PATTERN[v45]="v4.5-MaxPnL.py.*v4_5_maxpnl"
BOT_PID_PATTERN[v46]="v4.6-MaxPnL.py.*v4_6_maxpnl"
BOT_PID_PATTERN[v47]="v4.7-MaxPnL.py.*v4_7_maxpnl"
BOT_PID_PATTERN[v48]="v4.8-MaxPnL-Hybrid.py.*v4_8_hybrid"

STALL_THRESHOLD_SEC=1800   # 30 min without log activity = stalled

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Health check starting" >> "$HEALTH_LOG"

for key in v43 v44 v45 v46 v47 v48; do
    NAME="${BOT_NAME[$key]}"
    SCRIPT="${BOT_SCRIPT[$key]}"
    ARGS="${BOT_ARGS[$key]}"
    LOGFILE="${BOT_LOG[$key]}"
    DBFILE="${BOT_DB[$key]}"
    PATTERN="${BOT_PID_PATTERN[$key]}"

    NEEDS_RESTART=false
    RESTART_REASON=""
    PROCESS_DEAD=false
    DB_LOCKED=false
    LOG_STALLED=false

    # 1. Check process running
    PID=$(pgrep -f "$PATTERN" | head -1)
    if [ -z "$PID" ]; then
        PROCESS_DEAD=true
        NEEDS_RESTART=true
        RESTART_REASON="process not running"
        echo "  [$NAME] ❌ Process not found" >> "$HEALTH_LOG"
    else
        echo "  [$NAME] ✅ PID $PID running" >> "$HEALTH_LOG"
    fi

    # 2. Check log file activity (staleness)
    if [ -f "$LOGFILE" ]; then
        LAST_LOG=$(stat -c %Y "$LOGFILE" 2>/dev/null)
        LOG_AGE=$((NOW - LAST_LOG))
        if [ "$LOG_AGE" -gt "$STALL_THRESHOLD_SEC" ]; then
            LOG_STALLED=true
            echo "  [$NAME] ⚠️ Log stalled ${LOG_AGE}s (process may be quiet)" >> "$HEALTH_LOG"
            # Only flag for restart if process is also dead or DB is locked
            if [ "$PROCESS_DEAD" = true ] || [ "$DB_LOCKED" = true ]; then
                NEEDS_RESTART=true
                RESTART_REASON="${RESTART_REASON}, log stalled ${LOG_AGE}s"
            fi
        else
            echo "  [$NAME] ✅ Log active (${LOG_AGE}s ago)" >> "$HEALTH_LOG"
        fi
    else
        NEEDS_RESTART=true
        RESTART_REASON="log file missing"
        echo "  [$NAME] ❌ Log file missing" >> "$HEALTH_LOG"
    fi

    # 3. Check DB accessibility (no locks)
    if [ -f "$DBFILE" ]; then
        if timeout 5 sqlite3 "$DBFILE" "SELECT 1;" >/dev/null 2>&1; then
            echo "  [$NAME] ✅ DB accessible" >> "$HEALTH_LOG"
        else
            # Check for lock-holding processes
            LOCK_PIDS=$(lsof "$DBFILE" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ')
            if [ -n "$LOCK_PIDS" ]; then
                DB_LOCKED=true
                NEEDS_RESTART=true
                RESTART_REASON="DB locked by PIDs: $LOCK_PIDS"
                echo "  [$NAME] ❌ DB locked by PIDs: $LOCK_PIDS" >> "$HEALTH_LOG"
                # Kill lock holders
                for lp in $LOCK_PIDS; do
                    if [ "$lp" != "$PID" ]; then
                        echo "  [$NAME] Killing lock holder PID $lp" >> "$HEALTH_LOG"
                        kill -9 "$lp" 2>/dev/null
                    fi
                done
            else
                # DB timeout but no lock holder — could be corruption or slow query
                # Only restart if log is also stale (double signal)
                if [ "$LOG_STALLED" = true ]; then
                    NEEDS_RESTART=true
                    RESTART_REASON="DB timeout + log stalled"
                    echo "  [$NAME] ❌ DB timeout + log stalled — restarting" >> "$HEALTH_LOG"
                else
                    echo "  [$NAME] ⚠️ DB timeout but no lock holder found (log active, monitoring)" >> "$HEALTH_LOG"
                fi
            fi
        fi
    fi

    # 4. Final decision: log stall alone is NOT enough to restart if process+DB are healthy
    if [ "$LOG_STALLED" = true ] && [ "$PROCESS_DEAD" = false ] && [ "$DB_LOCKED" = false ] && [ -f "$LOGFILE" ]; then
        echo "  [$NAME] ✅ Log stalled but process alive + DB healthy — NOT restarting" >> "$HEALTH_LOG"
    fi

    # 4. Restart if needed
    if [ "$NEEDS_RESTART" = true ]; then
        echo "  [$NAME] 🔴 RESTARTING — $RESTART_REASON" >> "$HEALTH_LOG"

        # Kill existing process if any
        if [ -n "$PID" ]; then
            kill -9 "$PID" 2>/dev/null
            sleep 1
        fi

        # Also kill any zombie processes matching the pattern
        pgrep -f "$PATTERN" | while read zp; do
            kill -9 "$zp" 2>/dev/null
        done

        sleep 2

        # Restart
        cd "$BASE_DIR"
        nohup python3 "$SCRIPT" $ARGS >> "$LOGFILE" 2>&1 &
        NEW_PID=$!
        echo "  [$NAME] ✅ Restarted with PID $NEW_PID" >> "$HEALTH_LOG"

        # Send Telegram notification
        BOT_TOKEN="7924210747:AAFnN9lT4C_2c1awb1TpxG6wGifSFIdKnWE"
        CHAT_ID="-4798747409"
        MSG="🔴 [$NAME] Restarted\nReason: $RESTART_REASON\nNew PID: $NEW_PID\nTime: $(date '+%H:%M:%S')"
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d "chat_id=${CHAT_ID}" \
            -d "text=${MSG}" \
            -d "parse_mode=Markdown" > /dev/null 2>&1 &
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Health check done" >> "$HEALTH_LOG"
echo "" >> "$HEALTH_LOG"
