#!/usr/bin/env bash

# Limpa logs se for sexta-feira (antes de parar)
[ -x ./limpa_logs.sh ] && ./limpa_logs.sh

# Mata bot.py
pkill -f "python3 bot.py" 2>/dev/null

sleep 2

# Para Ollama de forma limpa
sudo systemctl stop ollama 2>/dev/null

# Se ainda estiver ativo, força
if systemctl is-active --quiet ollama 2>/dev/null; then
    sudo systemctl kill ollama 2>/dev/null
fi

exit 0
