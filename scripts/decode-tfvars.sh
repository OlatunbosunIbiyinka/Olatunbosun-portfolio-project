#!/usr/bin/env bash
# Decode base64 terraform.tfvars written on the ops VM.
# Usage:
#   ./scripts/decode-tfvars.sh                          # reads infra/terraform/envs/dev/terraform.tfvars.b64
#   ./scripts/decode-tfvars.sh ~/terraform.tfvars.b64   # paste file from laptop encode step
#   base64 -w0 < tfvars | ./scripts/decode-tfvars.sh -  # stdin

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_B64="${REPO_ROOT}/infra/terraform/envs/dev/terraform.tfvars.b64"
OUTPUT="${REPO_ROOT}/infra/terraform/envs/dev/terraform.tfvars"

input="${1:-$DEFAULT_B64}"

decode_to_output() {
  base64 -d >"$OUTPUT"
}

if [[ "$input" == "-" ]]; then
  echo "Decoding from stdin -> $OUTPUT"
  decode_to_output
elif [[ ! -f "$input" ]]; then
  echo "File not found: $input" >&2
  echo "Paste base64 into a file, e.g. nano ~/terraform.tfvars.b64" >&2
  exit 1
else
  echo "Decoding: $input"
  echo "Output:   $OUTPUT"
  base64 -d <"$input" >"$OUTPUT"
fi

mkdir -p "$(dirname "$OUTPUT")"
chmod 600 "$OUTPUT" 2>/dev/null || true

# Remove encoded file if it lived in the repo tree (keep ~/ paste files)
if [[ "$input" == "$DEFAULT_B64" && -f "$DEFAULT_B64" ]]; then
  rm -f "$DEFAULT_B64"
fi

if ! head -1 "$OUTPUT" | grep -qE '^#|^[a-z_]+'; then
  echo "WARN: output may be corrupt — check first lines:" >&2
  head -3 "$OUTPUT" >&2
  exit 1
fi

echo "OK. First lines:"
head -3 "$OUTPUT"
echo ""
echo "Verify: terraform fmt -check $OUTPUT  (from infra/terraform)"
