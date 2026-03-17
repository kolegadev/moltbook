#!/bin/bash
# Start Cloudflare tunnel for LLMHQ

# Kill existing
pkill -9 -f cloudflared 2>/dev/null
pkill -9 -f ngrok 2>/dev/null
pkill -9 -f "lt --port" 2>/dev/null
sleep 2

# Start LLMHQ server if not running
if ! curl -s http://127.0.0.1:8081/api/stats >/dev/null 2>&1; then
    cd /root/.openclaw/workspace/LLMHQm-work
    ./venv/bin/python3 dashboard_server.py > /tmp/dashboard-server.log 2>&1 &
    echo "LLMHQ server started"
    sleep 3
fi

# Start cloudflared
cloudflared tunnel --url http://localhost:8081 > /tmp/cloudflared.log 2>&1 &
CF_PID=$!
echo "Cloudflared PID: $CF_PID"

# Wait for URL
echo "Waiting for tunnel..."
sleep 8

# Extract and display URL
echo ""
echo "=== CLOUDFLARE TUNNEL URL ==="
grep -E "https://.*trycloudflare.com" /tmp/cloudflared.log | head -1 | grep -o "https://[^[:space:]]*"

echo ""
echo "=== LOG ==="
tail -5 /tmp/cloudflared.log