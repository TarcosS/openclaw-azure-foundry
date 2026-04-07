#!/bin/bash
# Post-deployment validation
set -e
RG="${1:-rg-openclaw}"
VM="${2:-vm-openclaw}"

echo "=== Checking cloud-init status ==="
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts "cloud-init status"

echo "=== Checking OpenClaw service ==="
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts "systemctl status openclaw"

echo "=== Checking OpenClaw status ==="
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts "sudo -u openclaw openclaw status"

echo "=== Checking Private Endpoint DNS resolution ==="
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts "nslookup oc-foundry-eus2.openai.azure.com"
