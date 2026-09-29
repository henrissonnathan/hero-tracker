"""Lembrete do caveman a cada mensagem do usuário (hook UserPromptSubmit).

Faz só isto:
  1. lê o JSON que o Claude Code manda na entrada (tem o texto da mensagem);
  2. se a mensagem PEDE troca de nível ("caveman ultra", "modo normal"...), grava
     o nível em .claude/caveman/nivel;
  3. imprime UMA linha com o nível atual. O Claude Code põe o que o hook imprime
     no contexto do modelo. Nível "off": não imprime nada.

Por que existe: sem lembrete, o estilo escorrega em conversa longa e a resposta
volta a crescer. O caveman original faz isso com dois hooks em Node; aqui é um
script só, em Python, sem rede, sem biblioteca de fora e sem arquivo fora do
projeto. Qualquer erro vira silêncio (sai com 0): lembrete que falha nunca pode
travar a mensagem do usuário.
"""
import json
import re
import sys
from pathlib import Path

ARQUIVO = Path(__file__).resolve().parent.parent / "caveman" / "nivel"
PADRAO = "full"

LEMBRETES = {
    "lite": "Caveman lite: sem enrolação nem rodeio, frases completas e curtas. "
            "Termos técnicos, números e erros exatos.",
    "full": "Caveman full: sem artigos, enrolação nem narração de ferramenta; "
            "frase curta (até 20 palavras), uma ideia por frase; termos técnicos, "
            "números e erros exatos. Aviso de segurança e ação irreversível: "
            "frase completa.",
    "ultra": "Caveman ultra: só o essencial, cada fato uma vez, sem abreviação "
             "inventada nem seta; termos técnicos, números e erros exatos. Aviso "
             "de segurança e ação irreversível: frase completa.",
}

# Só mensagem CURTA ou que começa com /caveman troca o nível: uma mensagem longa
# que apenas cita o caveman não pode mudar o estilo sem querer.
LIMITE_DE_PEDIDO = 60
PEDIDOS = [
    (r"modo normal|stop caveman|sem caveman|caveman off|"
     r"(parar?|para|desliga[r]?) (o )?caveman", "off"),
    (r"caveman[ -]?ultra", "ultra"),
    (r"caveman[ -]?lite", "lite"),
    (r"caveman[ -]?full|^/caveman\s*$", "full"),
]


def nivel_pedido(texto):
    t = texto.strip().lower()
    if len(t) > LIMITE_DE_PEDIDO and not t.startswith("/caveman"):
        return None
    for padrao, nivel in PEDIDOS:
        if re.search(padrao, t):
            return nivel
    return None


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    try:
        dados = json.loads(sys.stdin.read() or "{}")
    except Exception:
        dados = {}
    novo = nivel_pedido(str(dados.get("prompt", "")))
    try:
        if novo:
            ARQUIVO.parent.mkdir(parents=True, exist_ok=True)
            ARQUIVO.write_text(novo + "\n", encoding="utf-8")
        atual = ARQUIVO.read_text(encoding="utf-8").strip() if ARQUIVO.exists() else PADRAO
    except Exception:
        atual = PADRAO
    frase = LEMBRETES.get(atual)
    if frase:
        sys.stdout.write(frase + "\n")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
