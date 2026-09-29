#!/usr/bin/env bash
# Saída enxuta: roda um comando, guarda a saída INTEIRA num arquivo e mostra só o
# que decide — falha, erro, resumo.
#
# Por que existe: numa sessão de código, o que mais gasta token é saída de
# ferramenta, não a resposta. O caveman original resolve isso com o `shrink`, um
# binário de terceiros (licença BSL) que fica no meio do comando. Aqui é só um
# filtro local: nada sai do computador, e o original fica no disco para conferir.
#
# Uso:  bash scripts/enxuto.sh <comando e argumentos>
#   ex: bash scripts/enxuto.sh /c/flutter/bin/flutter.bat test
#       bash scripts/enxuto.sh /c/flutter/bin/flutter.bat analyze
# Saída completa: .dart_tool/saida-enxuta/ (fora do git; guarda as 20 últimas).
# Sai com o mesmo código do comando.

if [ $# -eq 0 ]; then
  echo "uso: bash scripts/enxuto.sh <comando e argumentos>" >&2
  exit 2
fi

pasta="$(cd "$(dirname "$0")/.." && pwd)/.dart_tool/saida-enxuta"
mkdir -p "$pasta"
log="$pasta/$(date +%Y%m%d-%H%M%S)-$$.log"

"$@" >"$log" 2>&1
codigo=$?

filtrar() { grep -aE "$1" "$log" | head -n "$2"; }

achado="$(case " $* " in
  *" test "*)
    # [E] = teste que falhou; Expected/Actual/Which = o porquê; Error: de
    # compilação aparece como arquivo.dart:linha:coluna.
    filtrar '\[E\]|Expected:|Actual:|Which:|Some tests failed|All tests passed|Failed to load|\.dart:[0-9]+:[0-9]+: Error' 80 ;;
  *" analyze "*)
    filtrar ' - (error|warning|info) - |issues? found|No issues found' 60 ;;
  *" build "*)
    filtrar 'FAILURE|BUILD FAILED|[Ee]rror:|Built build' 30 ;;
  *)
    filtrar '[Ee]rro|[Ff]alh|[Ff]ail|[Ww]arn|[Ee]xception' 40 ;;
esac)"

if [ -n "$achado" ]; then
  printf '%s\n' "$achado"
else
  echo "--- nada casou com o filtro; últimas linhas ---"
  tail -n 15 "$log"
fi
echo "código $codigo | $(wc -l <"$log") linhas | completo: $log"

# Guarda só as 20 mais recentes.
ls -1t "$pasta"/*.log 2>/dev/null | tail -n +21 | while IFS= read -r velho; do
  rm -f -- "$velho"
done
exit $codigo
