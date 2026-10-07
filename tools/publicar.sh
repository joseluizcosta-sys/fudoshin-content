#!/bin/bash
# Publica frases novas no GitHub Pages com um comando.
# Uso:  ./tools/publicar.sh            (publica)
#       ./tools/publicar.sh --disable  (desliga o conteúdo remoto; app volta às frases embutidas)
set -euo pipefail
cd "$(dirname "$0")/.."
PROJ="$(pwd)"
CONF="$PROJ/tools/publicar.conf"
REPO_DIR="$(dirname "$PROJ")/fudoshin-content"

if [ ! -f "$CONF" ]; then
  read -r -p "Seu usuário do GitHub: " GH_USER
  echo "GH_USER=$GH_USER" > "$CONF"
fi
source "$CONF"
URL="https://$GH_USER.github.io/fudoshin-content/manifest.json"

# 1. Numbers fechado (evita salvar por cima)
if pgrep -xq Numbers; then
  echo "✋ Feche o Numbers (Cmd+Q) e rode de novo."; exit 1
fi

# 2. Repositório do conteúdo
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Baixando o repositório fudoshin-content…"
  git clone "https://github.com/$GH_USER/fudoshin-content.git" "$REPO_DIR"
fi
git -C "$REPO_DIR" pull --quiet

# 3. Prévia do que muda
if [ "${1:-}" != "--disable" ]; then
  set +e; python3 tools/content_sheet.py preview; rc=$?; set -e
  [ $rc -eq 3 ] && exit 0
  [ $rc -ne 0 ] && exit $rc
  echo
  echo "Você testou essas frases no iPhone (Cmd+R + tela de debug)?"
  read -r -p "Publicar para todos os usuários? (s/N) " ok
  [ "$ok" = "s" ] || [ "$ok" = "S" ] || { echo "Cancelado. Nada foi publicado."; exit 0; }
  python3 tools/content_sheet.py publish
else
  read -r -p "DESLIGAR o conteúdo remoto para todos? (s/N) " ok
  [ "$ok" = "s" ] || [ "$ok" = "S" ] || { echo "Cancelado."; exit 0; }
  python3 tools/content_sheet.py publish --disable
fi

# 4. Copiar e enviar
VER=$(python3 -c "import json;print(json.load(open('dist/content/manifest.json'))['version'])")
cp dist/content/manifest.json "dist/content/content-v$VER.json" "$REPO_DIR/"
git -C "$REPO_DIR" add manifest.json "content-v$VER.json"
git -C "$REPO_DIR" commit --quiet -m "conteúdo v$VER"
git -C "$REPO_DIR" push --quiet

# 5. Registrar no projeto
git add Content/messages Content/Frases_Fudoshin.numbers dist tools 2>/dev/null || true
git commit --quiet -m "content: publicado v$VER" || true

# 6. Conferir se entrou no ar
echo "Enviado. Aguardando o GitHub Pages publicar (até 2 min)…"
for i in $(seq 1 12); do
  sleep 10
  NOW=$(curl -fsS "$URL?t=$(date +%s)" 2>/dev/null | python3 -c "import sys,json;print(json.load(sys.stdin)['version'])" 2>/dev/null || echo 0)
  if [ "$NOW" = "$VER" ]; then echo "✅ v$VER no ar: $URL"; exit 0; fi
done
echo "⚠️ Enviado, mas ainda não apareceu em $URL. Confira em alguns minutos."
