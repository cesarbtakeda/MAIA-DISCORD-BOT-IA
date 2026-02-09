#!/usr/bin/env bash
# Inicia Ollama + Bot Discord + limpa logs se for sexta

set -euo pipefail

# Verifica se o serviço existe
if [ ! -f /etc/systemd/system/ollama.service ]; then
    echo "Erro: ollama.service não encontrado."
    exit 1
fi

# Inicia/reinicia Ollama
sudo systemctl daemon-reload
sudo systemctl enable ollama >/dev/null 2>&1
sudo systemctl restart ollama

sleep 8

if ! systemctl is-active --quiet ollama; then
    echo "Erro: Ollama não iniciou."
    exit 1
fi

# Inicia bot se não estiver rodando
if pgrep -f "python3 bot.py" >/dev/null; then
    # Mesmo se bot já rodando, verifica logs se for sexta
    [ -x ./limpa_logs.sh ] && ./limpa_logs.sh
    exit 0
fi

# Usa venv se existir
if [ -d "venv" ] && [ -f "venv/bin/python3" ]; then
    nohup venv/bin/python3 bot.py > bot.log 2>&1 &
else
    nohup python3 bot.py > bot.log 2>&1 &
fi

# Limpa logs se for sexta-feira (depois de iniciar tudo)
[ -x ./limpa_logs.sh ] && ./limpa_logs.sh

exit 0
