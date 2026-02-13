#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_JSON="$SCRIPT_DIR/prompts.json"
OUT_DIR="$SCRIPT_DIR/generated"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "ERROR: OPENAI_API_KEY is not set."
  exit 1
fi

for cmd in curl jq base64; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing $cmd"; exit 1; }
done

MODEL="${OPENAI_IMAGE_MODEL:-gpt-image-1}"
SIZE="${OPENAI_IMAGE_SIZE:-1536x1024}"
mkdir -p "$OUT_DIR"

echo "Generating variations with model=$MODEL size=$SIZE"

jq -c '.[]' "$PROMPTS_JSON" | while IFS= read -r item; do
  id="$(jq -r '.id' <<< "$item")"
  prompt="$(jq -r '.prompt' <<< "$item")"
  out_file="$OUT_DIR/${id}.png"
  tmp_json="$OUT_DIR/${id}.response.json"
  echo "-> $id"

  payload="$(jq -n --arg model "$MODEL" --arg prompt "$prompt" --arg size "$SIZE" '{model:$model, prompt:$prompt, size:$size, n:1}')"

  curl -sS https://api.openai.com/v1/images/generations \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" > "$tmp_json"

  if jq -e '.error' "$tmp_json" >/dev/null 2>&1; then
    echo "ERROR generating $id:"
    jq '.error' "$tmp_json"
    continue
  fi

  b64="$(jq -r '.data[0].b64_json // empty' "$tmp_json")"
  url="$(jq -r '.data[0].url // empty' "$tmp_json")"

  if [[ -n "$b64" ]]; then
    printf '%s' "$b64" | base64 --decode > "$out_file"
    echo "   saved $out_file"
  elif [[ -n "$url" ]]; then
    curl -sS "$url" -o "$out_file"
    echo "   saved $out_file"
  else
    echo "ERROR: no image payload for $id"
  fi
done

echo "Done: $OUT_DIR"
