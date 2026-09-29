"""Tokens gastos pelas sessões do Claude Code neste projeto (skill caveman-stats).

Lê os registros .jsonl que o próprio Claude Code guarda no PC, em
~/.claude/projects/<pasta-do-projeto>/. Nada sai do computador.

Uso:  python stats.py            as 5 sessões mais recentes
      python stats.py --todas    todas as sessões deste projeto

Mostra o que foi GASTO. Não mostra economia: sem medir a mesma tarefa sem
caveman, economia é desconhecida.
"""
import json
import sys
from datetime import datetime
from pathlib import Path


def pasta_do_projeto():
    """C:\\a\\b vira C--a-b, que é como o Claude Code nomeia a pasta."""
    raiz = Path(__file__).resolve().parents[3]
    nome = str(raiz).replace(":", "-").replace("\\", "-").replace("/", "-")
    return Path.home() / ".claude" / "projects" / nome


def somar(arquivo):
    """Soma o uso por resposta. O registro repete o mesmo uso em cada bloco da
    resposta (texto, ferramenta...): conta cada resposta UMA vez, pelo id."""
    por_id = {}
    with open(arquivo, encoding="utf-8", errors="replace") as f:
        for linha in f:
            try:
                d = json.loads(linha)
            except ValueError:
                continue
            m = d.get("message") or {}
            uso = m.get("usage")
            if d.get("type") != "assistant" or not isinstance(uso, dict):
                continue
            por_id[m.get("id") or id(m)] = uso
    total = {"respostas": len(por_id), "saida": 0, "entrada": 0, "cache_lido": 0, "cache_gravado": 0}
    for uso in por_id.values():
        total["saida"] += uso.get("output_tokens") or 0
        total["entrada"] += uso.get("input_tokens") or 0
        total["cache_lido"] += uso.get("cache_read_input_tokens") or 0
        total["cache_gravado"] += uso.get("cache_creation_input_tokens") or 0
    return total


def mil(n):
    """1234 -> "1,2 mil"; 3400000 -> "3,4 mi" (com vírgula decimal)."""
    valor, unidade = (n / 1_000_000, "mi") if n >= 1_000_000 else (n / 1000, "mil")
    return f"{valor:,.1f} {unidade}".replace(",", "X").replace(".", ",").replace("X", ".")


def main():
    pasta = pasta_do_projeto()
    arquivos = sorted(pasta.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not arquivos:
        print(f"Nenhum registro de sessão em {pasta}")
        return 0
    if "--todas" not in sys.argv:
        arquivos = arquivos[:5]
    print(f"{'sessão':10} {'última atividade':17} {'respostas':>9} {'saída':>12} "
          f"{'entrada nova':>13} {'cache lido':>14} {'cache gravado':>14}")
    soma = {"respostas": 0, "saida": 0, "entrada": 0, "cache_lido": 0, "cache_gravado": 0}
    for a in arquivos:
        t = somar(a)
        for k in soma:
            soma[k] += t[k]
        quando = datetime.fromtimestamp(a.stat().st_mtime).strftime("%d/%m/%Y %H:%M")
        print(f"{a.stem[:8]:10} {quando:17} {t['respostas']:>9} {mil(t['saida']):>12} "
              f"{mil(t['entrada']):>13} {mil(t['cache_lido']):>14} {mil(t['cache_gravado']):>14}")
    if len(arquivos) > 1:
        print(f"{'TOTAL':28} {soma['respostas']:>9} {mil(soma['saida']):>12} "
              f"{mil(soma['entrada']):>13} {mil(soma['cache_lido']):>14} {mil(soma['cache_gravado']):>14}")
    print("Economia: desconhecida (não há medição da mesma tarefa sem caveman).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
