#!/bin/bash

TUNNEL_NAME="deskcrm-local"

echo "Iniciando Cloudflare Tunnel..."
cloudflared tunnel run $TUNNEL_NAME
