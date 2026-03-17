#!/bin/bash
# Step 1: Kill everything
pkill -9 -f ngrok
pkill -9 -f cloudflared  
pkill -9 -f "lt --port"
pkill -9 -f dashboard_server
sleep 2

echo "=== STEP 1: Starting PolyQuant (ngrok) ==="
cd /root/.openclaw-trading/skills/poly-quant
# Start PolyQuant server first if not running
if ! curl -s http://127.0.0.1:8080/api/stats >/dev/null 2>&1; then
    # Assuming PolyQuant has a start script
    nohup python3 app.py > /tmp/polyquant.log 2>&1 &
    sleep 3
fi
# Start ngrok for port 8080
nohup ngrok http 8080 > /tmp/ngrok.log 2>&1 &
echo "ngrok starting..."
sleep 5
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "PolyQuant URL: $NGROK_URL"

echo ""
echo "=== STEP 2: Starting LLMHQ ==="
cd /root/.openclaw/workspace/LLMHQm-work
./venv/bin/python3 dashboard_server.py > /tmp/dashboard-server.log 2>&1 &
echo "LLMHQ server starting..."
sleep 4

echo ""
echo "=== STEP 3: Starting Cloudflare Tunnel for LLMHQ ==="
nohup cloudflared tunnel --url http://localhost:8081 > /tmp/cloudflared.log 2>&1 &
echo "Cloudflared starting..."
sleep 10

echo ""
echo "=== FINAL STATUS ==="
echo "PolyQuant: $NGROK_URL"
echo -n "LLMHQ Cloudflare: "
tail -20 /tmp/cloudflared.log | grep -E "https://.*trycloudflare.com" | tail -1 | grep -o "https://[^[:space:]]*" || echo "(still connecting - check logs)"