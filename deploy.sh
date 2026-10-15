#!/usr/bin/env bash
# Netlify 手動デプロイ用スクリプト
#
# 使い方:
#   1. 初回のみ:  netlify login   （ブラウザで承認）
#   2. 公開:      ./deploy.sh
#
# このスクリプトは「下書きデプロイ → API で本番公開へ昇格」という手順で公開します。
# `netlify deploy --prod` が環境によって Forbidden になる事象を回避するための作りです。
# （まず通常の --prod を試し、失敗したら昇格方式にフォールバックします）

set -euo pipefail

SITE_ID="d8fe4cb1-6983-4327-b4f8-7eaf1da8d607"   # ryonma-car-chase
PROD_URL="https://ryonma-car-chase.netlify.app"

# ログイン確認
if ! netlify status >/dev/null 2>&1; then
  echo "Netlify にログインしていません。まず以下を実行してください:" >&2
  echo "  netlify login" >&2
  exit 1
fi

echo "▶ まず通常の本番デプロイを試します..."
if netlify deploy --prod --dir . --site "$SITE_ID"; then
  echo "✔ 本番公開しました: $PROD_URL"
  exit 0
fi

echo "△ 通常の --prod が失敗したため、昇格方式で公開します..."

# 下書きデプロイして deploy id を取得（JSON 出力）
DEPLOY_JSON="$(netlify deploy --dir . --site "$SITE_ID" --json)"
DEPLOY_ID="$(printf '%s' "$DEPLOY_JSON" | grep -o '"deploy_id"[^,]*' | head -1 | sed 's/.*: *"//;s/".*//')"

if [ -z "$DEPLOY_ID" ]; then
  echo "✖ deploy id を取得できませんでした。出力:" >&2
  printf '%s\n' "$DEPLOY_JSON" >&2
  exit 1
fi

echo "  下書き deploy_id=$DEPLOY_ID を本番へ昇格..."
netlify api restoreSiteDeploy --data "{\"site_id\":\"$SITE_ID\",\"deploy_id\":\"$DEPLOY_ID\"}" >/dev/null

echo "✔ 本番公開しました: $PROD_URL"
