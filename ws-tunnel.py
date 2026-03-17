#!/usr/bin/env python3
"""Simple WebSocket tunnel for LLMHQ dashboard"""
import asyncio
import websockets
import json
import aiohttp

async def proxy(websocket, path):
    """Proxy requests from WebSocket to local LLMHQ server"""
    async with aiohttp.ClientSession() as session:
        while True:
            try:
                message = await websocket.recv()
                data = json.loads(message)
                
                # Forward request to local server
                async with session.get('http://localhost:8081' + data.get('path', '/')) as resp:
                    body = await resp.text()
                    await websocket.send(json.dumps({
                        'status': resp.status,
                        'body': body
                    }))
            except Exception as e:
                await websocket.send(json.dumps({'error': str(e)}))

start_server = websockets.serve(proxy, '0.0.0.0', 8765)
print("WebSocket proxy started on ws://0.0.0.0:8765")
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()