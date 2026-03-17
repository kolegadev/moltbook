#!/bin/bash
# fix-tunnels.sh - Fix both dashboard tunnels

echo "=== Stopping all tunnels and servers ==="
pkill -9 -f ngrok 2>/dev/null
pkill -9 -f "lt --port" 2>/dev/null
pkill -9 -f dashboard_server.py 2>/dev/null
sleep 2

echo "=== Starting PolyQuant (port 8080) ==="
cd /root/.openclaw-trading/skills/poly-quant
nohup ngrok http 8080 > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
echo "ngrok PID: $NGROK_PID"

echo "=== Starting LLMHQ Dashboard (port 8081) ==="
cd /root/.openclaw/workspace/LLMHQm-work
nohup ./venv/bin/python3 dashboard_server.py > /tmp/dashboard-server.log 2>&1 &
DASH_PID=$!
echo "Dashboard PID: $DASH_PID"

sleep 5

echo ""
echo "=== Checking services ==="
ss -tlnp | grep -E "8080|8081"

echo ""
echo "=== Starting LLMHQ Tunnel ==="
nohup lt --port 8081 > /tmp/lt.log 2>&1 &
sleep 5

echo ""
echo "=== URLs ==="
echo "PolyQuant (ngrok):"
curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4

echo ""
echo "LLMHQ (localtunnel):"
cat /tmp/lt.log | grep "your url" | tail -1

echo ""
echo "=== Done ==="