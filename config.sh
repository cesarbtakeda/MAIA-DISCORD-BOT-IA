#!/usr/bin/env bash
c="clear"
set -euo pipefail

echo "Configurando Ollama + Bot Discord"

# 1. Instalar Ollama se necessário
if ! command -v ollama >/dev/null 2>&1; then
    echo "Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama já instalado."
fi

# 2. Criar usuário ollama (se não existir)
if ! id ollama >/dev/null 2>&1; then
    echo "Criando usuário ollama..."
    sudo useradd -r -s /bin/false -m -d /usr/share/ollama ollama
fi

# 3. Configurar serviço systemd (porta 8081)
echo "Configurando serviço systemd..."
sudo bash -c 'cat > /etc/systemd/system/ollama.service << "EOF"
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/home/kali/.local/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/home/kali/.dotnet/tools"
Environment="OLLAMA_HOST=0.0.0.0:8081"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_FLASH_ATTENTION=true"
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF'

# 4. Aplicar systemd + iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable ollama >/dev/null 2>&1
sudo systemctl restart ollama

sleep 10

if ! systemctl is-active --quiet ollama; then
    echo "ERRO: Ollama não iniciou."
    echo "Verifique: journalctl -u ollama -n 50 --no-pager"
    exit 1
fi

echo "Ollama rodando na porta 8081."

# 5. Configurar cliente Ollama para a porta correta
export OLLAMA_HOST=http://localhost:8081

# 6. Baixar modelo se não existir
if ! ollama list | grep -q "qwen2.5:3b"; then
    echo "Baixando qwen2.5:3b..."
    ollama pull qwen2.5:3b
else
    echo "Modelo qwen2.5:3b já baixado."
fi

# 7. Instalar dependências Python no venv
echo "Configurando ambiente Python..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# 8. Executar start.sh se existir e for executável
if [ -x ./start.sh ]; then
    echo "Executando start.sh..."
    ./start.sh
fi
# 9
chmod +x stop.sh


$c
echo "Ollama roda na prota 8081"
echo "Caso de erros: veja bot.log para detalhes"
echo "Para iniciar execute ./start.sh"
echo "Para parar execute ./stop.sh"
