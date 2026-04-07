#!/bin/bash
# Delete all OpenClaw resources
set -e
RG="${1:-rg-openclaw}"
echo "WARNING: This will delete ALL resources in $RG"
read -rp "Type the resource group name to confirm: " CONFIRM
if [ "$CONFIRM" != "$RG" ]; then
  echo "Aborted."
  exit 1
fi
az group delete -n "$RG" --yes --no-wait
echo "Deletion initiated for $RG (running in background)"
