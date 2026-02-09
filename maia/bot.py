import os
import discord
from discord import app_commands, File
import requests
from dotenv import load_dotenv
from datetime import datetime
import io

# Carrega o env.txt
load_dotenv("env.txt")

TOKEN = os.getenv("Token")
APPLICATION_ID = int(os.getenv("id"))

intents = discord.Intents.default()
client = discord.Client(intents=intents)
tree = app_commands.CommandTree(client)

OLLAMA_URL = "http://localhost:8081/api/generate"
MODEL = "qwen2.5:3b"

LOG_FILE = "bot_logs.txt"

def log_interaction(user: discord.User, query: str, response: str = None, error: str = None):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user_id = user.id
    display_name = user.display_name or user.name
    username = user.name

    log_line = f"[{now}] UserID: {user_id} | Display: {display_name} | @{username} | Prompt: {query}"

    if error:
        log_line += f" | ERRO: {error}"
    elif response:
        short = (response[:400] + "… [truncado no log]") if len(response) > 400 else response
        log_line += f" | Resposta (primeiros 400 chars): {short}"
    else:
        log_line += " | (sem resposta)"

    log_line += "\n"

    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(log_line)
    except Exception as e:
        print(f"Erro ao escrever log: {e}")

@client.event
async def on_ready():
    print(f"{client.user} está online!")
    try:
        synced = await tree.sync()
        print(f"Comandos sincronizados globalmente! ({len(synced)} comandos)")
        print(f"Logs salvos em: {os.path.abspath(LOG_FILE)}")
    except Exception as e:
        print(f"Erro ao sincronizar comandos: {e}")

@tree.command(name="prompt", description="Envia um prompt para a IA local (qwen2.5:3b)")
@app_commands.describe(query="O prompt/pergunta que você quer enviar à IA")
async def prompt(interaction: discord.Interaction, query: str):
    user = interaction.user
    log_interaction(user, query)  # log inicial

    await interaction.response.defer()

    try:
        payload = {
            "model": MODEL,
            "prompt": query,
            "stream": False
        }

        response = requests.post(OLLAMA_URL, json=payload, timeout=180)
        response.raise_for_status()

        result = response.json()
        resposta_ia = result.get("response", "Sem resposta da IA.").strip()

        # Log com a resposta (mesmo se longa)
        log_interaction(user, query, response=resposta_ia)

        MAX_FIELD = 1024

        if len(resposta_ia) <= MAX_FIELD:
            # Resposta curta → embed normal
            embed = discord.Embed(
                title="Resposta da IA (qwen2.5:3b)",
                description=f"**Seu prompt:**\n{query}",
                color=0x00cc99
            )
            embed.add_field(
                name="Resposta",
                value=f"```markdown\n{resposta_ia}\n```",
                inline=False
            )
            embed.set_footer(text=f"Enviado por: {user.display_name} | ID: {user.id}")

            await interaction.followup.send(embed=embed)

        else:
            # Resposta longa → embed de aviso + arquivo txt
            embed = discord.Embed(
                title="Resposta da IA (qwen2.5:3b)",
                description=f"**Seu prompt:**\n{query}",
                color=0xffaa00  # laranja para indicar que é longa
            )
            embed.add_field(
                name="Aviso",
                value=f"A resposta tem {len(resposta_ia)} caracteres (limite do embed: 1024).\n"
                      f"Foi enviada como arquivo abaixo.",
                inline=False
            )
            embed.set_footer(text=f"Enviado por: {user.display_name} | ID: {user.id} | {datetime.now().strftime('%d/%m/%Y %H:%M')}")

            # Cria o arquivo em memória
            txt_content = io.StringIO(resposta_ia)
            discord_file = File(txt_content, filename="resposta_ia.txt")

            await interaction.followup.send(embed=embed, file=discord_file)

    except requests.exceptions.RequestException as e:
        error_msg = f"Erro ao conectar com Ollama: {str(e)}"
        log_interaction(user, query, error=error_msg)
        await interaction.followup.send(error_msg, ephemeral=True)

    except Exception as e:
        error_msg = f"Erro inesperado: {str(e)}"
        log_interaction(user, query, error=error_msg)
        await interaction.followup.send(error_msg, ephemeral=True)

# Inicia o bot
client.run(TOKEN)
