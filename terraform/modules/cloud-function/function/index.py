import json
import os
import socket


def handler(event, context):
    host = os.environ.get("MINECRAFT_HOST", "127.0.0.1")
    port = int(os.environ.get("MINECRAFT_PORT", "25565"))
    online = False
    try:
        with socket.create_connection((host, port), timeout=3):
            online = True
    except OSError:
        online = False

    body = {
        "service": "minecraft",
        "host": host,
        "port": port,
        "online": online,
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
