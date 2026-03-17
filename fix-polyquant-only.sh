#!/bin/bash
# Stop everything
pkill -9 -f "lt --port" 2>/dev/null
pkill -9 -f ngrok 2>/dev/null
pkill -9 -f dashboard_server 2>/dev/null
pkill -9 -f pinggy 2>/dev/null
pkill -9 -f cloudflared 2>/dev/null
sleep 2

# Start only PolyQuant
cd /root/.openclaw-trading/skills/poly-quant
nohup ngrok http 8080 > /tmp/ngrok.log 2>&1 &
echo "PolyQuant ngrok started"
sleep 5
echo "URL:"
curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4