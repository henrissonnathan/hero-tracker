"""Confere se a versão COMPRIMIDA de um arquivo de memória manteve o que não pode
mudar. Parte da skill caveman-compress deste projeto.

Uso:  python validar.py <original> <comprimido>
Sai com código 1 e lista o que quebrou; 0 quando está tudo certo.

Escrito aqui, não copiado: o caveman original valida chamando programas dele e a
API da Anthropic. Este só compara os dois arquivos, sem rede.
"""
import re
import sys
from collections import Counter

NEGACOES_OBRIGATORIAS = ["nunca", "NUNCA", "não", "NÃO", "Não", "Nunca", "nenhum",
                         "nenhuma", "jamais", "proibido", "PROIBIDO", "Proibido"]


def ler(caminho):
    with open(caminho, encoding="utf-8") as f:
        return f.read().replace("\r\n", "\n")


def sem_linhas_de_cerca(texto):
    return "\n".join(l for l in texto.split("\n") if not l.lstrip().startswith("```"))


def titulos(texto):
    fora, dentro = [], False
    for l in texto.split("\n"):
        if l.lstrip().startswith("```"):
            dentro = not dentro
            continue
        if not dentro and l.startswith("#"):
            fora.append(l.strip())
    return fora


def conferir(original, comprimido):
    erros, avisos = [], []

    if titulos(original) != titulos(comprimido):
        erros.append("títulos (#) mudaram — a estrutura tem que ficar igual")

    n_o = sum(1 for l in original.split("\n") if l.lstrip().startswith("```"))
    n_c = sum(1 for l in comprimido.split("\n") if l.lstrip().startswith("```"))
    if n_o != n_c:
        erros.append(f"quantidade de cercas ``` mudou: {n_o} → {n_c}")

    cod_o = Counter(re.findall(r"`[^`\n]+`", sem_linhas_de_cerca(original)))
    cod_c = Counter(re.findall(r"`[^`\n]+`", sem_linhas_de_cerca(comprimido)))
    faltou = [c for c in cod_o if c not in cod_c]
    if faltou:
        erros.append("código entre crases sumiu: " + ", ".join(sorted(faltou)[:15]))
    inventado = [c for c in cod_c if c not in cod_o]
    if inventado:
        avisos.append("código entre crases NOVO (confira): " + ", ".join(sorted(inventado)[:10]))

    for nome, rx in [
        ("endereço (URL)", r"https?://[^\s)>\]`\"']+"),
        ("@import", r"^@\S+"),
        ("lei", r"\bL\d{1,2}\b"),
        ("arquivo", r"[\w\-/\.]+\.(?:dart|md|kt|kts|xml|json|yaml|yml|bat|ps1|sh|py|txt|db|apk|gradle|lock)\b"),
    ]:
        conj_o = set(re.findall(rx, original, flags=re.M))
        conj_c = set(re.findall(rx, comprimido, flags=re.M))
        falta = sorted(conj_o - conj_c)
        if falta:
            erros.append(f"{nome} sumiu: " + ", ".join(falta[:15]))

    nums_o = set(re.findall(r"\d+(?:[.,]\d+)*", original))
    nums_c = set(re.findall(r"\d+(?:[.,]\d+)*", comprimido))
    falta = sorted(nums_o - nums_c)
    if falta:
        erros.append("número sumiu (medição, versão, limite): " + ", ".join(falta[:20]))

    for palavra in NEGACOES_OBRIGATORIAS:
        rx = r"(?<![\wÀ-ÿ])" + re.escape(palavra) + r"(?![\wÀ-ÿ])"
        a, b = len(re.findall(rx, original)), len(re.findall(rx, comprimido))
        if b < a:
            erros.append(f'"{palavra}" aparece menos ({a} → {b}): negação some e o sentido inverte')

    return erros, avisos


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    original, comprimido = ler(sys.argv[1]), ler(sys.argv[2])
    erros, avisos = conferir(original, comprimido)
    t_o, t_c = len(original), len(comprimido)
    print(f"tamanho: {t_o} → {t_c} caracteres ({100 * (t_o - t_c) / max(t_o, 1):.0f}% menor)")
    for a in avisos:
        print("AVISO:", a)
    for e in erros:
        print("ERRO:", e)
    print("OK — nada que não podia mudar mudou." if not erros else f"{len(erros)} problema(s).")
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main())
